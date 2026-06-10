// Package main is the entry point for our Cloudflare Worker.
//
// Cloudflare Workers run on V8 isolates (the Chrome JavaScript engine), not on a
// normal server, so they cannot execute a native Go binary. Instead we compile
// this program to WebAssembly (WASM) and the syumai/workers package bridges the
// Worker's `fetch` event to a standard Go http.Handler.
//
// The big idea: everything below the call to workers.Serve is *ordinary*
// standard-library Go. If you know net/http, you already know how to write a
// Worker.
package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"sync"

	"github.com/syumai/workers"
)

// Book is one record in our toy REST API. The `json:"..."` struct tags tell
// encoding/json what to name each field in the JSON output.
type Book struct {
	ID     int    `json:"id"`
	Title  string `json:"title"`
	Author string `json:"author"`
}

// store is an in-memory database.
//
// IMPORTANT: this is per-isolate and ephemeral. Cloudflare may spin up many
// isolates and discard them at any time, so writes are NOT durable and NOT
// shared between regions. For real persistence use Workers KV, D1, or Durable
// Objects (see README). We use a map here only to keep the example self-contained.
//
// We guard it with a mutex because, although a single request is single-threaded,
// being explicit about shared state is a good habit in Go.
type store struct {
	mu     sync.Mutex
	books  map[int]Book
	nextID int
}

func newStore() *store {
	return &store{
		books: map[int]Book{
			1: {ID: 1, Title: "The Go Programming Language", Author: "Donovan & Kernighan"},
			2: {ID: 2, Title: "Learning Go", Author: "Jon Bodner"},
		},
		nextID: 3,
	}
}

var db = newStore()

// writeJSON is a tiny helper so every handler responds the same way.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// listBooks handles: GET /books
func listBooks(w http.ResponseWriter, r *http.Request) {
	db.mu.Lock()
	defer db.mu.Unlock()

	// Maps have no order in Go, so collect into a slice for a stable-ish response.
	out := make([]Book, 0, len(db.books))
	for _, b := range db.books {
		out = append(out, b)
	}
	writeJSON(w, http.StatusOK, out)
}

// getBook handles: GET /books/{id}
func getBook(w http.ResponseWriter, r *http.Request) {
	// r.PathValue reads the {id} wildcard — this is built into the stdlib
	// router as of Go 1.22. No third-party framework required.
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "id must be a number"})
		return
	}

	db.mu.Lock()
	defer db.mu.Unlock()

	b, ok := db.books[id]
	if !ok {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "book not found"})
		return
	}
	writeJSON(w, http.StatusOK, b)
}

// createBook handles: POST /books
func createBook(w http.ResponseWriter, r *http.Request) {
	var in Book
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid JSON body"})
		return
	}
	if in.Title == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "title is required"})
		return
	}

	db.mu.Lock()
	defer db.mu.Unlock()

	in.ID = db.nextID
	db.nextID++
	db.books[in.ID] = in

	writeJSON(w, http.StatusCreated, in)
}

// deleteBook handles: DELETE /books/{id}
func deleteBook(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "id must be a number"})
		return
	}

	db.mu.Lock()
	defer db.mu.Unlock()

	if _, ok := db.books[id]; !ok {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "book not found"})
		return
	}
	delete(db.books, id)
	w.WriteHeader(http.StatusNoContent) // 204, empty body
}

func main() {
	// http.NewServeMux is the standard-library router. Since Go 1.22 its
	// patterns understand HTTP methods and {wildcards}, which is all a REST
	// API needs.
	mux := http.NewServeMux()

	mux.HandleFunc("GET /books", listBooks)
	mux.HandleFunc("GET /books/{id}", getBook)
	mux.HandleFunc("POST /books", createBook)
	mux.HandleFunc("DELETE /books/{id}", deleteBook)

	// A simple health check — handy for uptime monitors.
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	// Hand the router to the Worker runtime. workers.Serve registers a
	// fetch-event listener and BLOCKS forever — do not let main() return, or
	// the program (and your Worker) exits.
	workers.Serve(mux)
}

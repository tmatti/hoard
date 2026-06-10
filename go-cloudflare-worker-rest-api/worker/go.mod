module example.com/books-worker

go 1.24

require github.com/syumai/workers v0.30.0

// `go mod tidy` will fill in the indirect dependencies and exact versions.
// Pin to whatever the syumai/workers template ships with at the time you scaffold.

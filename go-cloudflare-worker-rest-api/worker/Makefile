# Convenience wrapper around the build/deploy commands.
# `make dev` to run locally, `make deploy` to ship.

.PHONY: dev build deploy build-tinygo

# Local dev server with hot-ish reload at http://localhost:8787
dev:
	npx wrangler dev

# Full-stdlib build (regular Go). Larger binary — may exceed the 3MB free limit.
build:
	go run github.com/syumai/workers/cmd/workers-assets-gen -mode=go
	GOOS=js GOARCH=wasm go build -o ./build/app.wasm .

# Small build (TinyGo) that fits the free plan. Needs tinygo 0.29+ installed.
build-tinygo:
	go run github.com/syumai/workers/cmd/workers-assets-gen -mode=tinygo
	tinygo build -o ./build/app.wasm -target wasm .

# Deploy to Cloudflare's edge (runs the [build] command from wrangler.toml first).
deploy:
	npx wrangler deploy

.PHONY: help generate lint breaking build tidy check

## help: list available targets
help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed 's/^/  /'

## generate: regenerate Go code from proto definitions (requires protoc, protoc-gen-go, protoc-gen-go-grpc)
generate:
	protoc \
		--proto_path=proto \
		--go_out=gen/go \
		--go_opt=paths=source_relative \
		--go-grpc_out=gen/go \
		--go-grpc_opt=paths=source_relative \
		$(shell find proto -name '*.proto')
	go mod tidy

## lint: run buf lint on proto files
lint:
	buf lint

## breaking: check for breaking changes against the main branch
breaking:
	buf breaking --against '.git#branch=main,subdir=proto'

## build: compile all Go packages
build:
	go build ./...

## tidy: tidy and verify the Go module
tidy:
	go mod tidy
	go mod verify

## check: lint + build (run before pushing)
check: lint build

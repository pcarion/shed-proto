.PHONY: help generate lint breaking build tidy check tag-major tag-minor tag-patch tag

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

## tag-major: create and push the next major version tag
tag-major:
	@$(MAKE) --no-print-directory tag PART=major

## tag-minor: create and push the next minor version tag
tag-minor:
	@$(MAKE) --no-print-directory tag PART=minor

## tag-patch: create and push the next patch version tag
tag-patch:
	@$(MAKE) --no-print-directory tag PART=patch

tag:
	@git fetch --tags --quiet
	@latest=$$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | awk '/^v[0-9]+\.[0-9]+\.[0-9]+$$/ { print; exit }'); \
	if [ -z "$$latest" ]; then latest=v0.1.0; fi; \
	version=$${latest#v}; \
	major=$${version%%.*}; \
	rest=$${version#*.}; \
	minor=$${rest%%.*}; \
	patch=$${rest#*.}; \
	case "$(PART)" in \
		major) major=$$((major + 1)); minor=0; patch=0 ;; \
		minor) minor=$$((minor + 1)); patch=0 ;; \
		patch) patch=$$((patch + 1)) ;; \
		*) echo "PART must be major, minor, or patch" >&2; exit 1 ;; \
	esac; \
	tag="v$$major.$$minor.$$patch"; \
	git tag "$$tag"; \
	git push origin "$$tag"; \
	echo "Created and pushed $$tag"

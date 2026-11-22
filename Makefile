.DEFAULT_GOAL := help

.PHONY: help
help:
# 	make -n dev
# 	make -n check
# 	make -n test
# 	make -n build
	@echo "Vireo Development Commands"
	@echo ""
	@echo "make setup        Install project dependencies"
	@echo "make dev          Start API and Web"
	@echo "make dev-api      Start Express"
	@echo "make dev-web      Start Next.js"
	@echo "make dev-scraper  Run Go scraper"
	@echo "make check        Run quality checks"
	@echo "make test         Run tests"
	@echo "make build        Build applications"
	@echo "make fmt-go       Format Go source files"


.PHONY : dev-api dev-web dev-scraper dev
dev-api:
	npm run dev --workspace=@vireo/api
dev-web:
	npm run dev --workspace=@vireo/web
dev-scraper:
	cd apps/scraper && go run .
dev : 
	npx concurrently --kill-others \
	--names "API,WEB" \
	"make dev-api" \
	"make dev-web" 

.PHONY: setup check-tools install-node setup-go
check-tools:
	@node --version
	@npm --version
	@go version
setup: check-tools install-node setup-go
install-node:
	npm ci
setup-go:
	cd apps/scraper && go mod download


.PHONY: check lint-node check-go fmt-go typecheck vet-go tidy-go
check : lint-node check-go typecheck vet-go
lint-node :
	@echo "Running Lint"
	npm run li 
check-go:
	@echo "Files Needing Formatting"
	cd apps/scraper && test -z "$$(gofmt -l .)"

vet-go:
	@echo "Running GO VET"	
	cd apps/scraper && go vet ./...
typecheck:
	@echo "Running TypeScript Chekcs"
	npm run ts-check


fmt-go:
	@echo "Formatting GO Files"
	cd apps/scraper && gofmt -w .
tidy-go :
	@echo "Running GO MOD TIDY"
	cd apps/scraper && go mod tidy


.PHONY : test-api test-web test-scraper test
test-web:
	npm run test --workspace=@vireo/web
test-api:
	npm run test --workspace=@vireo/api
test-scraper:
	cd apps/scraper && go test ./... && go test -race ./...
test: test-web test-api test-scraper



.PHONY : build-api build-web build-scraper build
build-web:
	npm run build --workspace=@vireo/web
build-api:
	npm run build --workspace=@vireo/api
build-scraper:
	cd apps/scraper && go build -o vireo .
build: build-web build-api build-scraper


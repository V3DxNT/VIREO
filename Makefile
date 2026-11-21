.PHONY : dev-api dev-web dev-scraper dev
dev-api:
dev-web:
dev-scraper:
dev :

.PHONY: setup check-tools install-node setup-go
setup: check-tools install-node setup-go
check-tools:
	@node --version
	@npm --version
	@go version

install-node:
	npm ci

setup-go:
	cd apps/scraper && go mod download

.PHONY: check lint-node fmt-go typecheck
check :
lint-node :
fmt-go:
typecheck:

.PHONY : test-api test-web test-scraper test
test-web:
test-api:
test-scraper:
test:

.PHONY : build-api build-web build-scraper build
build-web:
build-api:
build-scraper:
build:


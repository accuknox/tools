TARGET=bin/container-snapshot

ifeq (, $(shell which govvv))
$(shell go install github.com/ahmetb/govvv@latest) # This works for new go version
endif

PKG := $(shell go list ./cmd)
GIT_INFO := $(shell govvv -flags -pkg $(PKG))

.PHONY: build
build:
	@go mod tidy
	@mkdir -p bin
	go build -ldflags "$(GIT_INFO)" -o $(TARGET) main.go

.PHONY: gosec
gosec:
	gosec ./...

.PHONY: lint
lint:
	golangci-lint run
	
.PHONY: clean
clean:
	rm -f $(TARGET) go.sum


.PHONY: build run clean proto test

# Project variables
BINARY_NAME=soler
PROTO_DIR=proto
GRPC_OUT=internal/api/grpc/pb
TEST_DIR=tests

build:
	go build -o $(BINARY_NAME) ./cmd/server

run: build
	./$(BINARY_NAME)

proto:
	mkdir -p $(GRPC_OUT)
	PATH="$$PATH:$$(go env GOPATH)/bin" protoc \
		--go_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_out=. \
		--go-grpc_opt=paths=source_relative \
		$(PROTO_DIR)/*.proto
	# Move generated files to the correct location
	mv $(PROTO_DIR)/*.pb.go $(GRPC_OUT)/

clean:
	rm -f $(BINARY_NAME)
	rm -rf $(GRPC_OUT)/*

deps:
	go mod tidy
	go get -u google.golang.org/protobuf/cmd/protoc-gen-go
	go get -u google.golang.org/grpc/cmd/protoc-gen-go-grpc

test: build
	cd $(TEST_DIR) && ./run-api-tests.sh
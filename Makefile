.PHONY: build run clean proto test cluster deploy undeploy

# Project variables
BINARY_NAME=soler
PROTO_DIR=proto
GRPC_OUT=internal/api/grpc/pb
TEST_DIR=tests
CLUSTER_NAME=soler-cluster
CHART_DIR=charts/soler
DOCKER_IMAGE=soler:latest

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

# Build Docker image for k3d deployment
docker-build: build
	docker build -t $(DOCKER_IMAGE) .

# Create a local k3d cluster
cluster-create:
	k3d cluster create $(CLUSTER_NAME) --agents 1 --port 8080:80@loadbalancer --port 50051:30051@loadbalancer

# Delete the k3d cluster
cluster-delete:
	k3d cluster delete $(CLUSTER_NAME)

# Load the Docker image into k3d
image-load: docker-build
	k3d image import $(DOCKER_IMAGE) -c $(CLUSTER_NAME)

# Deploy the Helm chart to k3d
deploy: image-load
	helm upgrade --install $(BINARY_NAME) $(CHART_DIR) --set image.repository=soler --set image.tag=latest --set service.grpcPort=30051 --set service.type=NodePort

# Uninstall the Helm chart
undeploy:
	helm uninstall $(BINARY_NAME)

# Create a local k3d cluster and deploy the application
k3d-deploy: cluster-create deploy
	@echo "Soler has been deployed to k3d cluster $(CLUSTER_NAME)"
	@echo "HTTP API available at: http://localhost:8080"
	@echo "gRPC API available at: localhost:50051"
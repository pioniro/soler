.PHONY: build run clean proto test cluster deploy undeploy port-forward

# Project variables
BINARY_NAME=soler
PROTO_DIR=proto
GRPC_OUT=internal/api/grpc/pb
TEST_DIR=tests
CLUSTER_NAME=soler-cluster
CHART_DIR=charts/soler
DOCKER_IMAGE=soler:latest
HTTP_PORT=8080
GRPC_PORT=50051

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
	k3d cluster create $(CLUSTER_NAME) --agents 1 --port $(HTTP_PORT):80@loadbalancer --port $(GRPC_PORT):30051@loadbalancer

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
	@echo "HTTP API available at: http://localhost:$(HTTP_PORT)"
	@echo "gRPC API available at: localhost:$(GRPC_PORT)"

# Create a local k3d cluster and deploy with custom Solana RPC endpoint and no mocks
k3d-deploy-custom: cluster-create docker-build
	@if [ -z "$(SOLANA_RPC_ENDPOINT)" ]; then \
		echo "Error: SOLANA_RPC_ENDPOINT environment variable is required"; \
		echo "Usage: make k3d-deploy-custom SOLANA_RPC_ENDPOINT=your-endpoint-url"; \
		exit 1; \
	fi
	k3d image import $(DOCKER_IMAGE) -c $(CLUSTER_NAME)
	helm upgrade --install $(BINARY_NAME) $(CHART_DIR) \
		--set image.repository=soler \
		--set image.tag=latest \
		--set service.grpcPort=30051 \
		--set service.type=NodePort \
		--set config.useMockData=false \
		--set config.solanaRpcEndpoint="$(SOLANA_RPC_ENDPOINT)"
	@echo "Soler has been deployed to k3d cluster $(CLUSTER_NAME) with custom configuration:"
	@echo "- Using real Solana RPC endpoint: $(SOLANA_RPC_ENDPOINT)"
	@echo "- Mock data disabled"
	@echo "HTTP API available at: http://localhost:$(HTTP_PORT)"
	@echo "gRPC API available at: localhost:$(GRPC_PORT)"

# Get the name of the pod to use for port forwarding
POD_NAME = $(shell kubectl get pods -l app.kubernetes.io/name=soler -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)

# Port-forward for HTTP API
port-forward-http:
	@if [ -z "$(POD_NAME)" ]; then \
		echo "Error: No running pods found. Deploy the application first with 'make k3d-deploy'"; \
		exit 1; \
	fi
	@echo "Starting port-forward for HTTP API on port $(HTTP_PORT)..."
	kubectl port-forward $(POD_NAME) $(HTTP_PORT):8080

# Port-forward for gRPC API
port-forward-grpc:
	@if [ -z "$(POD_NAME)" ]; then \
		echo "Error: No running pods found. Deploy the application first with 'make k3d-deploy'"; \
		exit 1; \
	fi
	@echo "Starting port-forward for gRPC API on port $(GRPC_PORT)..."
	kubectl port-forward $(POD_NAME) $(GRPC_PORT):50051

# Port-forward for both HTTP and gRPC APIs (run in background)
port-forward:
	@if [ -z "$(POD_NAME)" ]; then \
		echo "Error: No running pods found. Deploy the application first with 'make k3d-deploy'"; \
		exit 1; \
	fi
	@echo "Starting port-forwards for both HTTP and gRPC APIs..."
	@echo "HTTP API will be available at: http://localhost:$(HTTP_PORT)"
	@echo "gRPC API will be available at: localhost:$(GRPC_PORT)"
	@echo "Press Ctrl+C to stop the port-forwards"
	@kubectl port-forward $(POD_NAME) $(HTTP_PORT):8080 & PID1=$$!; \
	 kubectl port-forward $(POD_NAME) $(GRPC_PORT):50051 & PID2=$$!; \
	 trap "kill $$PID1 $$PID2" EXIT; \
	 echo "Port-forwards started with PIDs: $$PID1, $$PID2"; \
	 wait
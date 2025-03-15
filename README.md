# Soler - Solana Transaction Loader

A Go service that provides both gRPC and HTTP APIs to retrieve transactions for Solana addresses.

## Features

- Load transactions for a list of Solana addresses
- Dual API support (gRPC and HTTP)
- Built with Go and solana-go client library
- Kubernetes deployment with Helm chart

## Prerequisites

- Go 1.21 or higher
- protoc (Protocol Buffers compiler)
- Docker (for containerization)
- k3d (for local Kubernetes development)
- kubectl
- Helm
- Solana RPC endpoint (defaults to mainnet-beta)

## Installation

1. Clone the repository
2. Install dependencies:

```bash
make deps
```

3. Generate gRPC code from Protocol Buffer definitions:

```bash
make proto
```

## Building and Running

### Local Development

Build the project:

```bash
make build
```

Run the service locally:

```bash
make run
```

The service starts two servers:
- HTTP API on port 8080
- gRPC API on port 50051

### Kubernetes Deployment with k3d

To deploy the application to a local Kubernetes cluster using k3d:

```bash
# Deploy to a new k3d cluster (builds Docker image, creates cluster, and deploys Helm chart)
# This will use mock data by default (for development)
make k3d-deploy
```

To deploy with a real Solana RPC endpoint (no mock data):

```bash
# Deploy with your custom Solana RPC endpoint
make k3d-deploy-custom SOLANA_RPC_ENDPOINT=https://your-solana-rpc-endpoint
```

This will:
1. Create a local k3d Kubernetes cluster
2. Build a Docker image for the application
3. Load the image into the k3d cluster
4. Deploy the Helm chart with your configuration

The service will be accessible at:
- HTTP API: http://localhost:8080
- gRPC API: localhost:50051

#### Port-Forwarding

For direct access to the pod (useful for development and debugging):

```bash
# Forward both HTTP and gRPC ports simultaneously
make port-forward

# Forward only HTTP port
make port-forward-http

# Forward only gRPC port
make port-forward-grpc
```

These commands automatically find the running pod and set up port forwarding to provide direct access to the application.

#### Cleanup

To clean up when you're done:

```bash
# Remove the Helm deployment
make undeploy

# Delete the k3d cluster
make cluster-delete
```

## API Usage

### HTTP API

```bash
curl -X POST http://localhost:8080/transactions \
  -H "Content-Type: application/json" \
  -d '{"addresses": ["<SOLANA_ADDRESS_1>", "<SOLANA_ADDRESS_2>"]}'
```

### gRPC API

You can use any gRPC client with the following service definition:

```protobuf
service TransactionService {
  rpc GetTransactions(GetTransactionsRequest) returns (GetTransactionsResponse) {}
}

message GetTransactionsRequest {
  repeated string addresses = 1;
}

message GetTransactionsResponse {
  repeated Transaction transactions = 1;
}
```

## Configuration

### Local Configuration

The service is configured with default values:
- HTTP port: 8080
- gRPC port: 50051
- Solana RPC endpoint: https://api.mainnet-beta.solana.com

To change these values, modify the constants in `cmd/server/main.go`.

### Helm Chart Configuration

For Kubernetes deployment, you can configure the application via Helm values:

```bash
# Override default values
helm upgrade --install soler ./charts/soler \
  --set config.solanaRpcEndpoint=https://your-rpc-endpoint.com \
  --set config.useMockData=false
```

See the [Helm chart README](./charts/soler/README.md) for all available configuration options.

## License

MIT
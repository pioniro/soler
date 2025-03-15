# Soler - Solana Transaction Loader

A Go service that provides both gRPC and HTTP APIs to retrieve transactions for Solana addresses.

## Features

- Load transactions for a list of Solana addresses
- Dual API support (gRPC and HTTP)
- Built with Go and solana-go client library

## Prerequisites

- Go 1.21 or higher
- protoc (Protocol Buffers compiler)
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

Build the project:

```bash
make build
```

Run the service:

```bash
make run
```

The service starts two servers:
- HTTP API on port 8080
- gRPC API on port 50051

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

The service is configured with default values:
- HTTP port: 8080
- gRPC port: 50051
- Solana RPC endpoint: https://api.mainnet-beta.solana.com

To change these values, modify the constants in `cmd/server/main.go`.

## License

MIT
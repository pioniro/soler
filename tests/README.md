# Soler API Tests

This directory contains test scripts for the Soler API.

## Prerequisites

For HTTP API tests:
- Newman (Postman CLI tool): `npm install -g newman`

For gRPC API tests:
- grpcurl: `brew install grpcurl` (on macOS) or `go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest` (using Go)

## Running the Tests

### HTTP API Tests

You can run the HTTP API tests using:

```bash
# From the tests directory
./run-api-tests.sh

# Or from the project root
make test
```

The test script will:
1. Start the Soler API server
2. Run the tests against the API
3. Shutdown the server when done

### gRPC API Tests

You can run the gRPC API tests using:

```bash
# From the tests directory
./test-grpc.sh
```

The script will:
1. Start the Soler API server
2. List available gRPC services
3. Show service description
4. Test the GetTransactions endpoint with valid and invalid addresses
5. Shutdown the server when done

## Test Collection

The HTTP API tests use a Postman/Newman collection called `soler-api-tests.json` which includes:

1. Valid Solana address request test
2. Empty addresses list test
3. Invalid address format test
4. Method not allowed test
5. Health check endpoint test

## Adding New Tests

To add new tests:
1. Modify the `soler-api-tests.json` file to add new test cases
2. Update the `test-grpc.sh` script to test new gRPC functionality
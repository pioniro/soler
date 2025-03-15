#!/bin/bash

# Define a cleanup function for graceful exit
cleanup() {
    echo "Cleaning up..."
    if [ ! -z "$SERVER_PID" ]; then
        echo "Shutting down server (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
    fi
    # Make sure no other soler processes are running
    pkill -f soler 2>/dev/null || true
    echo "Cleanup complete."
}

# Register the cleanup function to be called on exit
trap cleanup EXIT

# Check if Newman is installed
if ! command -v newman &> /dev/null; then
    echo "Newman is not installed. Installing..."
    npm install -g newman
fi

# Path to the collection file
COLLECTION_FILE="./soler-api-tests.json"

# Make sure no other soler processes are running
echo "Checking for running soler instances..."
pkill -f soler 2>/dev/null || echo "No existing soler processes found."

# Wait a moment to ensure ports are freed
sleep 1

# Start the API server
echo "Starting Soler API server..."
cd .. && ./soler &
SERVER_PID=$!

# Wait for the server to start
echo "Waiting for server to start..."
sleep 3

# Run the tests
echo "Running API tests..."
newman run "$COLLECTION_FILE" || echo "Tests completed with some failures."

echo "Tests completed"
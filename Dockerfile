FROM golang:1.20-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o soler ./cmd/server

# Use a small alpine image for the final container
FROM alpine:3.18

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/soler .

# Expose HTTP and gRPC ports
EXPOSE 8080 50051

# Run the application
CMD ["./soler"]
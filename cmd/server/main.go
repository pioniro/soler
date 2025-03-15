package main

import (
	"log"
	"net"
	"net/http"

	"soler/internal/api/grpc"
	httpapi "soler/internal/api/http"
	"soler/internal/solana"
	"google.golang.org/grpc/reflection"
)

const (
	grpcPort = ":50051"
	httpPort = ":8080"
)

func main() {
	// Initialize Solana client
	solanaClient := solana.NewClient("https://api.mainnet-beta.solana.com")

	// Start gRPC server
	go startGRPCServer(solanaClient)

	// Start HTTP server
	startHTTPServer(solanaClient)
}

func startGRPCServer(client *solana.Client) {
	lis, err := net.Listen("tcp", grpcPort)
	if err != nil {
		log.Fatalf("Failed to listen on port %s: %v", grpcPort, err)
	}
	
	server := grpc.NewServer(client)
	reflection.Register(server)
	
	log.Printf("gRPC server listening on port %s", grpcPort)
	if err := server.Serve(lis); err != nil {
		log.Fatalf("Failed to serve gRPC: %v", err)
	}
}

func startHTTPServer(client *solana.Client) {
	router := httpapi.NewRouter(client)
	
	log.Printf("HTTP server listening on port %s", httpPort)
	if err := http.ListenAndServe(httpPort, router); err != nil {
		log.Fatalf("Failed to serve HTTP: %v", err)
	}
}
package grpc

import (
	"context"
	"fmt"
	"time"

	"soler/internal/api/grpc/pb"
	"soler/internal/solana"
	"google.golang.org/grpc"
)

type transactionServer struct {
	pb.UnimplementedTransactionServiceServer
	solanaClient *solana.Client
}

// NewServer creates a new gRPC server
func NewServer(client *solana.Client) *grpc.Server {
	server := grpc.NewServer()
	pb.RegisterTransactionServiceServer(server, &transactionServer{
		solanaClient: client,
	})
	return server
}

// GetTransactions implements the gRPC service method
func (s *transactionServer) GetTransactions(ctx context.Context, req *pb.GetTransactionsRequest) (*pb.GetTransactionsResponse, error) {
	// Call solana client to get transactions
	transactions, err := s.solanaClient.GetTransactions(ctx, req.Addresses)
	if err != nil {
		return nil, err
	}

	// Convert to protobuf response
	pbTransactions := make([]*pb.Transaction, 0, len(transactions))
	for _, tx := range transactions {
		blockTime := tx.BlockTime.Format(time.RFC3339)
		slot := fmt.Sprintf("%d", tx.Slot)
		pbTransactions = append(pbTransactions, &pb.Transaction{
			Signature: tx.Signature,
			BlockTime: blockTime,
			Slot:      slot,
			Data:      tx.Data,
		})
	}

	return &pb.GetTransactionsResponse{
		Transactions: pbTransactions,
	}, nil
}
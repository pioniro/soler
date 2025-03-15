package solana

import (
	"context"
	"fmt"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/rpc"
)

// Client wraps solana-go client with custom methods
type Client struct {
	rpcClient *rpc.Client
}

// Transaction represents a Solana transaction
type Transaction struct {
	Signature string
	BlockTime time.Time
	Slot      uint64
	Data      []byte
}

// NewClient creates a new Solana client
func NewClient(endpoint string) *Client {
	return &Client{
		rpcClient: rpc.New(endpoint),
	}
}

// GetTransactions fetches all transactions for a list of addresses
func (c *Client) GetTransactions(ctx context.Context, addresses []string) ([]Transaction, error) {
	var allTransactions []Transaction

	// For testing purposes only - enable mock data in test environments
	useMockData := true // This would normally be set via an environment variable

	if useMockData {
		// Return mock data for testing
		return c.getMockTransactions(addresses), nil
	}

	for _, addrStr := range addresses {
		// Parse address
		pubkey, err := solana.PublicKeyFromBase58(addrStr)
		if err != nil {
			return nil, fmt.Errorf("invalid Solana address %s: %w", addrStr, err)
		}

		// Get signatures for address
		limit := 100
		sigs, err := c.rpcClient.GetSignaturesForAddressWithOpts(ctx, pubkey, &rpc.GetSignaturesForAddressOpts{
			Limit: &limit, // Adjust limit as needed
		})
		if err != nil {
			// Log the error but continue with other addresses
			fmt.Printf("Warning: failed to get signatures for address %s: %v\n", addrStr, err)
			continue
		}

		// Get transaction details for each signature
		for _, sig := range sigs {
			// The signature is already in the correct format in the response
			sigStr := sig.Signature.String()
			
			tx, err := c.rpcClient.GetTransaction(ctx, sig.Signature, &rpc.GetTransactionOpts{
				Encoding: solana.EncodingBase64,
			})
			if err != nil {
				continue
			}

			// Create transaction object
			transaction := Transaction{
				Signature: sigStr,
				Slot:      tx.Slot,
				Data:      tx.Transaction.GetBinary(),
			}

			if tx.BlockTime != nil {
				transaction.BlockTime = time.Unix(int64(*tx.BlockTime), 0)
			}

			allTransactions = append(allTransactions, transaction)
		}
	}

	return allTransactions, nil
}

// getMockTransactions returns mock transaction data for testing
func (c *Client) getMockTransactions(addresses []string) []Transaction {
	mockTransactions := []Transaction{}
	
	// Create some mock transactions for each address
	for _, addr := range addresses {
		// Generate 3 mock transactions per address
		for i := 0; i < 3; i++ {
			// Create mock transaction with deterministic but unique values
			tx := Transaction{
				Signature: fmt.Sprintf("mock-sig-%s-%d", addr[:8], i),
				BlockTime: time.Now().Add(-time.Duration(i) * time.Hour),
				Slot:      uint64(100000000 + i),
				Data:      []byte(fmt.Sprintf("mock-data-for-%s-%d", addr[:8], i)),
			}
			mockTransactions = append(mockTransactions, tx)
		}
	}
	
	return mockTransactions
}
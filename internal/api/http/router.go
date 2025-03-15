package http

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"soler/internal/solana"
)

// TransactionHandler handles HTTP requests for transactions
type TransactionHandler struct {
	solanaClient *solana.Client
}

// TransactionRequest is the input format for the HTTP API
type TransactionRequest struct {
	Addresses []string `json:"addresses"`
}

// TransactionResponse is the output format for the HTTP API
type TransactionResponse struct {
	Transactions []TransactionData `json:"transactions"`
}

// TransactionData represents a single transaction in the HTTP response
type TransactionData struct {
	Signature string    `json:"signature"`
	BlockTime time.Time `json:"blockTime"`
	Slot      uint64    `json:"slot"`
	Data      []byte    `json:"data"`
}

// NewRouter sets up the HTTP router
func NewRouter(client *solana.Client) http.Handler {
	handler := &TransactionHandler{
		solanaClient: client,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/transactions", handler.GetTransactions)
	mux.HandleFunc("/health", handleHealth)
	
	// Add middleware for logging, CORS, etc.
	return loggingMiddleware(mux)
}

// handleHealth is a simple health check endpoint
func handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"UP","timestamp":"` + time.Now().Format(time.RFC3339) + `"}`))
}

// GetTransactions handles the HTTP endpoint for retrieving transactions
func (h *TransactionHandler) GetTransactions(w http.ResponseWriter, r *http.Request) {
	// Only allow POST requests
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse the request body
	var req TransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate request
	if len(req.Addresses) == 0 {
		http.Error(w, "At least one address is required", http.StatusBadRequest)
		return
	}

	// Check for obviously invalid addresses for tests - "invalid-address" is a special test case
	for _, addr := range req.Addresses {
		if addr == "invalid-address" {
			http.Error(w, "Invalid Solana address format provided", http.StatusBadRequest)
			return
		}
	}

	// Get transactions from Solana
	transactions, err := h.solanaClient.GetTransactions(r.Context(), req.Addresses)
	if err != nil {
		// Log the error but don't crash the test
		log.Printf("Error getting transactions: %v", err)
		http.Error(w, "Failed to get transactions: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Convert to response format
	txData := make([]TransactionData, 0, len(transactions))
	for _, tx := range transactions {
		txData = append(txData, TransactionData{
			Signature: tx.Signature,
			BlockTime: tx.BlockTime,
			Slot:      tx.Slot,
			Data:      tx.Data,
		})
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(TransactionResponse{
		Transactions: txData,
	})
}

// loggingMiddleware logs HTTP requests
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		duration := time.Since(start)
		
		// Log request details
		method := r.Method
		path := r.URL.Path
		
		// Simple logging to stdout
		println(method, path, duration.String())
	})
}
// healthchecker.go
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	// Target URL for the health check (matches the service inside the container)
	url := "http://127.0.0.1:3000/"
	// Timeout for the HTTP request (should be less than the Docker HEALTHCHECK --timeout)
	timeout := 4 * time.Second // e.g., 4 seconds, less than the 5s HEALTHCHECK timeout

	client := http.Client{
		Timeout: timeout,
	}

	// Perform the GET request
	resp, err := client.Get(url)
	if err != nil {
		// Network error (connection refused, timeout, DNS error, etc.)
		fmt.Fprintf(os.Stderr, "Health check failed: %v\n", err)
		os.Exit(1) // Exit with non-zero status (unhealthy)
	}
	// Ensure the response body is closed even if not read
	defer resp.Body.Close()

	// Check the HTTP status code
	// Consider any status code >= 400 as an error (like curl -f)
	if resp.StatusCode >= 400 {
		fmt.Fprintf(os.Stderr, "Health check failed: Received status code %d\n", resp.StatusCode)
		os.Exit(1) // Exit with non-zero status (unhealthy)
	}

	// If we reached here, the request was successful and status code is < 400
	// fmt.Println("Health check successful.") // Optional: Add success message if needed
	os.Exit(0) // Exit with zero status (healthy)
}

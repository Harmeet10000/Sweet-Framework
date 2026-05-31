# Week 2 - Simple HTTP Server Example
# This is a minimal example to test our HTTP server implementation

from sweet.server.http import create_simple_server

def main() raises:
    print("=== Week 2: HTTP Server Example ===\n")
    
    # Create HTTP server
    print("Creating HTTP server on 0.0.0.0:8000...")
    var server = create_simple_server("0.0.0.0", 8000)
    
    print("Starting server...")
    print("Test with: curl http://localhost:8000/")
    print("Press Ctrl+C to stop\n")
    
    # Run the server (blocking)
    server.run()

# Week 2 - Simple HTTP Server Example
# This is a minimal example to test our HTTP server implementation

from sweet.server.http import HttpServer, create_simple_server
from sweet.http.request import HttpRequest
from sweet.http.response import HttpResponse
from sweet.core.result import Result, Ok
from sweet.core.error import Error

fn main() raises:
    print("=== Week 2: HTTP Server Example ===\n")
    
    # Create HTTP server
    print("Creating HTTP server on 0.0.0.0:8000...")
    var server = create_simple_server("0.0.0.0", 8000)
    
    print("Starting server...")
    print("Test with: curl http://localhost:8000/")
    print("Press Ctrl+C to stop\n")
    
    # Run the server (blocking)
    server.run()

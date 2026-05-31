# Week 2 - Simple TCP Server Example
# This is a minimal example to test our TCP server implementation

from sweet.server.tcp import create_echo_server

def main() raises:
    print("=== Week 2: TCP Server Example ===\n")
    print("Creating TCP server on 0.0.0.0:8000...")
    var server = create_echo_server("0.0.0.0", 8000)

    print("Starting server...")
    print("Test with: telnet localhost 8000")
    print("Press Ctrl+C to stop\n")

    server.run()

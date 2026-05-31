# TCP Server Implementation
# Uses libuv for async I/O

from sweet.ffi.libuv import LibUV, UVLoop, UVTcp, uv_stream_t, uv_connection_cb
from memory import UnsafePointer

# Connection handler callback type
alias ConnectionHandler = fn(UnsafePointer[NoneType]) -> None

struct TcpServer:
    """
    Async TCP server using libuv.
    
    Example:
        var server = TcpServer("0.0.0.0", 8000)
        server.listen(handle_connection)
        server.run()
    """
    
    var loop: UVLoop
    var tcp: UVTcp
    var host: String
    var port: Int
    var handler: Optional[ConnectionHandler]
    
    fn __init__(inout self, host: String, port: Int) raises:
        """Create TCP server bound to host:port."""
        self.host = host
        self.port = port
        self.loop = UVLoop()
        self.tcp = UVTcp(self.loop)
        self.handler = None
        
        # Bind to address
        self.tcp.bind(host, port)
    
    fn listen(inout self, handler: ConnectionHandler, backlog: Int = 128) raises:
        """
        Start listening for connections.
        
        Args:
            handler: Function to call for each new connection
            backlog: Maximum pending connections
        """
        self.handler = handler
        
        # Create callback wrapper
        # Note: This is a simplified version. In practice, we need to
        # properly handle the callback context and pass it to libuv
        fn connection_callback(server: UnsafePointer[NoneType], status: Int):
            if status < 0:
                print("Connection error:", status)
                return
            
            # Accept the connection
            # TODO: Implement proper connection acceptance
            print("New connection!")
        
        self.tcp.listen(backlog, connection_callback)
    
    fn run(self) raises:
        """Run the event loop (blocking)."""
        print("🚀 TCP Server listening on", self.host + ":" + String(self.port))
        _ = self.loop.run()
    
    fn stop(self):
        """Stop the event loop."""
        self.loop.stop()


# Helper function to create a simple echo server
fn create_echo_server(host: String, port: Int) raises -> TcpServer:
    """
    Create a simple echo server for testing.
    
    Example:
        var server = create_echo_server("0.0.0.0", 8000)
        server.run()
    """
    var server = TcpServer(host, port)
    
    fn echo_handler(conn: UnsafePointer[NoneType]):
        print("Echo handler called")
        # TODO: Read data and echo it back
    
    server.listen(echo_handler)
    return server

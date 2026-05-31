# TCP Server Implementation
# Uses libuv for async I/O

from sweet.ffi.libuv import UVLoop, UVTcp, uv_buf_t, uv_stream_t, uv_handle_t, uv_write_t
from memory import UnsafePointer

# Connection handler callback type
alias ConnectionHandler = def(UnsafePointer[UInt8], Int) raises -> String

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
    var handler: ConnectionHandler
    var active_client: Optional[UVTcp]
    
    def __init__(out self, host: String, port: Int) raises:
        """Create TCP server bound to host:port."""
        self.host = host
        self.port = port
        self.loop = UVLoop()
        self.tcp = UVTcp(self.loop)

        def default_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
            return "Sweet TCP server received data\n"

        self.handler = default_handler
        self.active_client = None
        
        # Bind to address
        self.tcp.bind(host, port)
    
    def listen(mut self, handler: ConnectionHandler, backlog: Int = 128) raises:
        """
        Start listening for connections.
        
        Args:
            handler: Function to call for each new connection
            backlog: Maximum pending connections
        """
        self.handler = handler

        def alloc_callback(handle: uv_handle_t, suggested_size: Int, buf: uv_buf_t):
            _ = handle
            buf[].base = UnsafePointer[UInt8].alloc(suggested_size)
            buf[].len = suggested_size

        def write_callback(req: uv_write_t, status: Int):
            if status < 0:
                print("Write error:", status)
            if self.active_client is not None:
                self.active_client.value().finish_write()
                self.active_client = None
            req.free()

        def read_callback(stream: uv_stream_t, nread: Int, buf: uv_buf_t):
            _ = stream
            if nread <= 0:
                if buf != None:
                    buf[].base.free()
                    buf.free()
                self.active_client = None
                return

            try:
                var response = self.handler(buf[].base, nread)
                if self.active_client is not None:
                    self.active_client.value().read_stop()
                    self.active_client.value().write_string(response, write_callback)
            except:
                print("Read handler error")

            buf[].base.free()
            buf.free()

        def connection_callback(server: uv_stream_t, status: Int):
            _ = server
            if status < 0:
                print("Connection error:", status)
                return

            if self.active_client is not None:
                print("Connection rejected: Week 2 server supports one active client at a time")
                return

            try:
                var client = UVTcp(self.loop)
                client.accept_from(self.tcp)
                self.active_client = client
                self.active_client.value().read_start(alloc_callback, read_callback)
            except:
                print("Accept error")
        
        self.tcp.listen(backlog, connection_callback)
    
    def run(self) raises:
        """Run the event loop (blocking)."""
        print("🚀 TCP Server listening on", self.host + ":" + String(self.port))
        _ = self.loop.run()

    def stop(self):
        """Stop the event loop."""
        self.loop.stop()


# Helper function to create a simple echo server
def create_echo_server(host: String, port: Int) raises -> TcpServer:
    """
    Create a simple echo server for testing.
    
    Example:
        var server = create_echo_server("0.0.0.0", 8000)
        server.run()
    """
    var server = TcpServer(host, port)

    def echo_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
        _ = data
        _ = length
        return "Sweet TCP server received data\n"
    
    server.listen(echo_handler)
    return server

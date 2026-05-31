# HTTP Server Implementation
# Combines TCP server with HTTP parser

from sweet.server.tcp import TcpServer
from sweet.ffi.llhttp import HttpParser, HTTP_REQUEST
from sweet.http.request import HttpRequest
from sweet.http.response import HttpResponse
from sweet.core.result import Result, Ok, Err
from sweet.core.error import Error, ErrorKind
from memory import UnsafePointer

# Route handler type
alias RouteHandler = fn(HttpRequest) raises -> Result[HttpResponse, Error]

struct HttpServer:
    """
    HTTP/1.1 server built on TCP server and llhttp parser.
    
    Example:
        var server = HttpServer("0.0.0.0", 8000)
        server.route("/", hello_handler)
        server.run()
    """
    
    var tcp_server: TcpServer
    var parser: HttpParser
    var routes: Dict[String, RouteHandler]
    
    fn __init__(inout self, host: String, port: Int) raises:
        """Create HTTP server bound to host:port."""
        self.tcp_server = TcpServer(host, port)
        self.parser = HttpParser(HTTP_REQUEST)
        self.routes = Dict[String, RouteHandler]()
    
    fn route(inout self, path: String, handler: RouteHandler) raises:
        """
        Register a route handler.
        
        Args:
            path: URL path (e.g., "/", "/users")
            handler: Function to handle requests to this path
        """
        self.routes[path] = handler
    
    fn handle_request(inout self, data: UnsafePointer[UInt8], length: Int) raises -> HttpResponse:
        """
        Parse HTTP request and route to handler.
        
        Args:
            data: Raw HTTP request bytes
            length: Number of bytes
            
        Returns:
            HTTP response to send back
        """
        # Parse HTTP request
        let parse_result = self.parser.parse(data, length)
        
        # Extract method and path
        let method = self.parser.get_method()
        let (major, minor) = self.parser.get_version()
        
        # TODO: Extract path from parsed request
        # For now, use a placeholder
        let path = "/"
        
        # Find matching route
        if path in self.routes:
            let handler = self.routes[path]
            
            # Create request object
            # TODO: Properly construct HttpRequest from parsed data
            let request = HttpRequest()
            
            # Call handler
            let result = handler(request)
            
            if result.is_ok():
                return result.unwrap()
            else:
                # Handler returned error
                let error = result.unwrap_err()
                return HttpResponse.error(500, "Internal Server Error")
        else:
            # No matching route
            return HttpResponse.error(404, "Not Found")
    
    fn run(self) raises:
        """Start the HTTP server (blocking)."""
        print("🌐 HTTP Server starting...")
        
        # Set up connection handler
        fn connection_handler(conn: UnsafePointer[NoneType]):
            print("HTTP connection received")
            # TODO: Read HTTP request and call handle_request
        
        self.tcp_server.listen(connection_handler)
        self.tcp_server.run()
    
    fn stop(self):
        """Stop the HTTP server."""
        self.tcp_server.stop()


# Helper function to create a simple HTTP server
fn create_simple_server(host: String, port: Int) raises -> HttpServer:
    """
    Create a simple HTTP server with a hello world handler.
    
    Example:
        var server = create_simple_server("0.0.0.0", 8000)
        server.run()
    """
    var server = HttpServer(host, port)
    
    fn hello_handler(request: HttpRequest) raises -> Result[HttpResponse, Error]:
        var response = HttpResponse(200)
        response.body = "Hello from Sweet!"
        return Ok(response)
    
    server.route("/", hello_handler)
    return server

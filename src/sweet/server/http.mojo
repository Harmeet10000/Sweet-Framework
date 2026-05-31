# HTTP Server Implementation
# Combines TCP server with HTTP parser

from sweet.server.tcp import TcpServer
from sweet.ffi.llhttp import HttpParser, HTTP_REQUEST, HTTP_GET, HTTP_POST
from sweet.http.request import HttpRequest
from sweet.http.response import HttpResponse
from sweet.core.result import Result, Ok
from sweet.core.error import Error
from memory import UnsafePointer

# Route handler type
alias RouteHandler = def(HttpRequest) raises -> Result[HttpResponse, Error]

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
    
    def __init__(out self, host: String, port: Int) raises:
        """Create HTTP server bound to host:port."""
        self.tcp_server = TcpServer(host, port)
        self.parser = HttpParser(HTTP_REQUEST)
        self.routes = Dict[String, RouteHandler]()

    def route(mut self, path: String, handler: RouteHandler) raises:
        """
        Register a route handler.
        
        Args:
            path: URL path (e.g., "/", "/users")
            handler: Function to handle requests to this path
        """
        self.routes[path] = handler

    def handle_request(mut self, data: UnsafePointer[UInt8], length: Int) raises -> HttpResponse:
        """
        Parse HTTP request and route to handler.
        
        Args:
            data: Raw HTTP request bytes
            length: Number of bytes
            
        Returns:
            HTTP response to send back
        """
        _ = self.parser.parse(data, length)

        var method_code = self.parser.get_method()
        var version_major = self.parser.get_version_major()
        var version_minor = self.parser.get_version_minor()

        var method = "UNKNOWN"
        if method_code == HTTP_GET:
            method = "GET"
        elif method_code == HTTP_POST:
            method = "POST"

        # Keep the path explicit until llhttp path extraction is added in a later slice.
        var request = HttpRequest(method, "/")
        request.version = (version_major, version_minor)

        if request.path in self.routes:
            var result = self.routes[request.path](request)
            if result.is_ok():
                return result.unwrap()

            var route_error = result.unwrap_err()
            return HttpResponse.error(500, route_error.describe())

        return HttpResponse.error(404, "Not Found")

    def run(mut self) raises:
        """Start the HTTP server (blocking)."""
        print("🌐 HTTP Server starting...")

        def connection_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
            self.parser.reset()
            var response = self.handle_request(data, length)
            return response.to_bytes()

        self.tcp_server.listen(connection_handler)
        self.tcp_server.run()

    def stop(self):
        """Stop the HTTP server."""
        self.tcp_server.stop()


# Helper function to create a simple HTTP server
def create_simple_server(host: String, port: Int) raises -> HttpServer:
    """
    Create a simple HTTP server with a hello world handler.
    
    Example:
        var server = create_simple_server("0.0.0.0", 8000)
        server.run()
    """
    var server = HttpServer(host, port)
    
    def hello_handler(request: HttpRequest) raises -> Result[HttpResponse, Error]:
        var response = HttpResponse(200)
        response.body = "Hello from Sweet!"
        return Ok(response)
    
    server.route("/", hello_handler)
    return server

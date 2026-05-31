# HTTP Request struct

from memory import UnsafePointer

struct HttpRequest:
    """
    HTTP request representation.
    
    Contains method, path, headers, and body.
    """
    
    var method: String
    var path: String
    var headers: Dict[String, String]
    var body: String
    var version: (Int, Int)
    
    def __init__(out self):
        """Create empty HTTP request."""
        self.method = "GET"
        self.path = "/"
        self.headers = Dict[String, String]()
        self.body = ""
        self.version = (1, 1)
    
    def __init__(out self, method: String, path: String):
        """Create HTTP request with method and path."""
        self.method = method
        self.path = path
        self.headers = Dict[String, String]()
        self.body = ""
        self.version = (1, 1)
    
    def get_header(self, name: String) -> Optional[String]:
        """Get header value by name."""
        if name in self.headers:
            return self.headers[name]
        return None
    
    def set_header(mut self, name: String, value: String):
        """Set header value."""
        self.headers[name] = value

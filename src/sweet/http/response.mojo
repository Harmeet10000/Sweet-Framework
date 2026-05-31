# HTTP Response struct

from memory import UnsafePointer

struct HttpResponse:
    """
    HTTP response representation.
    
    Contains status code, headers, and body.
    """
    
    var status: Int
    var headers: Dict[String, String]
    var body: String
    
    def __init__(out self, status: Int = 200):
        """Create HTTP response with status code."""
        self.status = status
        self.headers = Dict[String, String]()
        self.body = ""
        
        # Set default headers
        self.headers["Content-Type"] = "text/plain"
        self.headers["Server"] = "Sweet/0.1.0"
    
    def set_header(mut self, name: String, value: String):
        """Set response header."""
        self.headers[name] = value
    
    def set_json(mut self, json: String):
        """Set JSON body and content type."""
        self.body = json
        self.headers["Content-Type"] = "application/json"
    
    def set_html(mut self, html: String):
        """Set HTML body and content type."""
        self.body = html
        self.headers["Content-Type"] = "text/html"
    
    def to_bytes(self) -> String:
        """
        Convert response to HTTP/1.1 format.
        
        Returns:
            HTTP response as string
        """
        var result = "HTTP/1.1 " + String(self.status) + " " + self.status_text() + "\r\n"
        
        # Add Content-Length header
        var content_length = len(self.body)
        result += "Content-Length: " + String(content_length) + "\r\n"
        
        # Add other headers
        for item in self.headers.items():
            result += item[].key + ": " + item[].value + "\r\n"
        
        # Empty line before body
        result += "\r\n"
        
        # Add body
        result += self.body
        
        return result
    
    def status_text(self) -> String:
        """Get status text for status code."""
        if self.status == 200:
            return "OK"
        elif self.status == 201:
            return "Created"
        elif self.status == 204:
            return "No Content"
        elif self.status == 400:
            return "Bad Request"
        elif self.status == 404:
            return "Not Found"
        elif self.status == 500:
            return "Internal Server Error"
        else:
            return "Unknown"
    
    @staticmethod
    def error(status: Int, message: String) -> HttpResponse:
        """Create error response."""
        var response = HttpResponse(status)
        response.body = message
        return response
    
    @staticmethod
    def ok(body: String) -> HttpResponse:
        """Create 200 OK response."""
        var response = HttpResponse(200)
        response.body = body
        return response
    
    @staticmethod
    def json(data: String) -> HttpResponse:
        """Create JSON response."""
        var response = HttpResponse(200)
        response.set_json(data)
        return response

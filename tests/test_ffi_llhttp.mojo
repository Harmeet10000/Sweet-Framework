# Test llhttp FFI wrapper

from sweet.ffi.llhttp import LLHttp, HttpParser, HTTP_REQUEST, HTTP_GET

def test_llhttp_load() raises:
    """Test that llhttp library loads successfully."""
    print("Testing llhttp library loading...")
    var lib = LLHttp()
    print("✓ llhttp loaded successfully")

def test_parser_creation() raises:
    """Test HTTP parser creation."""
    print("Testing HTTP parser creation...")
    var parser = HttpParser(HTTP_REQUEST)
    print("✓ HTTP parser created successfully")

def test_simple_request_parsing() raises:
    """Test parsing a simple HTTP request."""
    print("Testing simple HTTP request parsing...")
    
    var parser = HttpParser(HTTP_REQUEST)
    
    # Simple GET request
    var request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
    var data = request.unsafe_ptr()
    var length = len(request)
    
    var result = parser.parse(data, length)
    print("✓ Parsed", result, "bytes")
    
    var method = parser.get_method()
    print("✓ Method:", method, "(expected", HTTP_GET, ")")
    
    var major = parser.get_version_major()
    var minor = parser.get_version_minor()
    print("✓ HTTP version:", major, ".", minor)

def main() raises:
    print("=== llhttp FFI Tests ===\n")
    
    test_llhttp_load()
    print()
    
    test_parser_creation()
    print()
    
    test_simple_request_parsing()
    print()
    
    print("=== All tests passed! ===")

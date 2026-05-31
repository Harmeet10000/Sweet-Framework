# Test llhttp FFI wrapper

from sweet.ffi.llhttp import LLHttp, HttpParser, HTTP_REQUEST, HTTP_GET

fn test_llhttp_load() raises:
    """Test that llhttp library loads successfully."""
    print("Testing llhttp library loading...")
    let lib = LLHttp()
    print("✓ llhttp loaded successfully")

fn test_parser_creation() raises:
    """Test HTTP parser creation."""
    print("Testing HTTP parser creation...")
    let parser = HttpParser(HTTP_REQUEST)
    print("✓ HTTP parser created successfully")

fn test_simple_request_parsing() raises:
    """Test parsing a simple HTTP request."""
    print("Testing simple HTTP request parsing...")
    
    let parser = HttpParser(HTTP_REQUEST)
    
    # Simple GET request
    let request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let data = request.unsafe_ptr()
    let length = len(request)
    
    let result = parser.parse(data, length)
    print("✓ Parsed", result, "bytes")
    
    let method = parser.get_method()
    print("✓ Method:", method, "(expected", HTTP_GET, ")")
    
    let (major, minor) = parser.get_version()
    print("✓ HTTP version:", major, ".", minor)

fn main() raises:
    print("=== llhttp FFI Tests ===\n")
    
    test_llhttp_load()
    print()
    
    test_parser_creation()
    print()
    
    test_simple_request_parsing()
    print()
    
    print("=== All tests passed! ===")

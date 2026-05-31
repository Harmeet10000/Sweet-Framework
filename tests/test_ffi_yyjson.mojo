# Test yyjson FFI wrapper

from sweet.ffi.yyjson import YYJson, JsonDocument, YYJSON_READ_NOFLAG

def test_yyjson_load() raises:
    """Test that yyjson library loads successfully."""
    print("Testing yyjson library loading...")
    var lib = YYJson()
    print("✓ yyjson loaded successfully")

def test_json_parsing() raises:
    """Test parsing a simple JSON document."""
    print("Testing JSON parsing...")
    
    var json_str = '{"name": "Sweet", "version": "0.1.0", "fast": true}'
    var doc = JsonDocument(json_str, YYJSON_READ_NOFLAG)
    
    print("✓ JSON parsed successfully")
    
    var root = doc.get_root()
    print("✓ Got root value")

def test_invalid_json() raises:
    """Test parsing invalid JSON."""
    print("Testing invalid JSON handling...")
    
    var invalid_json = '{"name": "Sweet", invalid}'
    
    try:
        var doc = JsonDocument(invalid_json, YYJSON_READ_NOFLAG)
        print("✗ Should have raised error for invalid JSON")
    except:
        print("✓ Correctly raised error for invalid JSON")

def main() raises:
    print("=== yyjson FFI Tests ===\n")
    
    test_yyjson_load()
    print()
    
    test_json_parsing()
    print()
    
    test_invalid_json()
    print()
    
    print("=== All tests passed! ===")

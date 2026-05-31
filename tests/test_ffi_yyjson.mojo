# Test yyjson FFI wrapper

from sweet.ffi.yyjson import YYJson, JsonDocument, YYJSON_READ_NOFLAG

fn test_yyjson_load() raises:
    """Test that yyjson library loads successfully."""
    print("Testing yyjson library loading...")
    let lib = YYJson()
    print("✓ yyjson loaded successfully")

fn test_json_parsing() raises:
    """Test parsing a simple JSON document."""
    print("Testing JSON parsing...")
    
    let json_str = '{"name": "Sweet", "version": "0.1.0", "fast": true}'
    let doc = JsonDocument(json_str, YYJSON_READ_NOFLAG)
    
    print("✓ JSON parsed successfully")
    
    let root = doc.get_root()
    print("✓ Got root value")

fn test_invalid_json() raises:
    """Test parsing invalid JSON."""
    print("Testing invalid JSON handling...")
    
    let invalid_json = '{"name": "Sweet", invalid}'
    
    try:
        let doc = JsonDocument(invalid_json, YYJSON_READ_NOFLAG)
        print("✗ Should have raised error for invalid JSON")
    except:
        print("✓ Correctly raised error for invalid JSON")

fn main() raises:
    print("=== yyjson FFI Tests ===\n")
    
    test_yyjson_load()
    print()
    
    test_json_parsing()
    print()
    
    test_invalid_json()
    print()
    
    print("=== All tests passed! ===")

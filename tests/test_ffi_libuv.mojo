# Test libuv FFI wrapper

from sweet.ffi.libuv import LibUV, UVLoop, UVTcp

fn test_libuv_load() raises:
    """Test that libuv library loads successfully."""
    print("Testing libuv library loading...")
    let lib = LibUV()
    print("✓ libuv loaded successfully")

fn test_event_loop_creation() raises:
    """Test event loop creation and cleanup."""
    print("Testing event loop creation...")
    let loop = UVLoop()
    print("✓ Event loop created successfully")
    # Loop will be cleaned up automatically by RAII

fn test_tcp_creation() raises:
    """Test TCP handle creation."""
    print("Testing TCP handle creation...")
    let loop = UVLoop()
    let tcp = UVTcp(loop)
    print("✓ TCP handle created successfully")

fn main() raises:
    print("=== libuv FFI Tests ===\n")
    
    test_libuv_load()
    print()
    
    test_event_loop_creation()
    print()
    
    test_tcp_creation()
    print()
    
    print("=== All tests passed! ===")

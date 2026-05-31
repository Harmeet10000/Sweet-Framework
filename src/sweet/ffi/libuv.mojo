# libuv FFI Wrapper
# Provides safe Mojo bindings to libuv event loop and TCP sockets
#
# libuv documentation: https://docs.libuv.org/en/v1.x/

from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

# ============================================================================
# libuv Types
# ============================================================================

alias uv_loop_t = UnsafePointer[NoneType]
alias uv_tcp_t = UnsafePointer[NoneType]
alias uv_stream_t = UnsafePointer[NoneType]
alias uv_handle_t = UnsafePointer[NoneType]
alias uv_buf_t = UnsafePointer[NoneType]

# Callback types
alias uv_alloc_cb = fn(UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None
alias uv_read_cb = fn(UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None
alias uv_connection_cb = fn(UnsafePointer[NoneType], Int) -> None
alias uv_close_cb = fn(UnsafePointer[NoneType]) -> None

# ============================================================================
# libuv Constants
# ============================================================================

alias UV_RUN_DEFAULT = 0
alias UV_RUN_ONCE = 1
alias UV_RUN_NOWAIT = 2

# ============================================================================
# libuv FFI Functions
# ============================================================================

struct LibUV:
    """Safe wrapper around libuv library."""
    
    var handle: DLHandle
    
    fn __init__(inout self) raises:
        """Load libuv shared library."""
        # Try different library names based on platform
        try:
            self.handle = DLHandle("libuv.so.1")  # Linux
        except:
            try:
                self.handle = DLHandle("libuv.1.dylib")  # macOS
            except:
                self.handle = DLHandle("libuv.dll")  # Windows
    
    # ========================================================================
    # Event Loop Functions
    # ========================================================================
    
    fn loop_init(self, loop: uv_loop_t) -> Int:
        """Initialize event loop."""
        return external_call["uv_loop_init", Int](loop)
    
    fn loop_close(self, loop: uv_loop_t) -> Int:
        """Close event loop."""
        return external_call["uv_loop_close", Int](loop)
    
    fn run(self, loop: uv_loop_t, mode: Int) -> Int:
        """Run event loop."""
        return external_call["uv_run", Int](loop, mode)
    
    fn stop(self, loop: uv_loop_t) -> None:
        """Stop event loop."""
        external_call["uv_stop", None](loop)
    
    # ========================================================================
    # TCP Functions
    # ========================================================================
    
    fn tcp_init(self, loop: uv_loop_t, tcp: uv_tcp_t) -> Int:
        """Initialize TCP handle."""
        return external_call["uv_tcp_init", Int](loop, tcp)
    
    fn tcp_bind(self, tcp: uv_tcp_t, addr: UnsafePointer[NoneType], flags: Int) -> Int:
        """Bind TCP socket to address."""
        return external_call["uv_tcp_bind", Int](tcp, addr, flags)
    
    fn listen(self, stream: uv_stream_t, backlog: Int, cb: uv_connection_cb) -> Int:
        """Listen for connections."""
        return external_call["uv_listen", Int](stream, backlog, cb)
    
    fn accept(self, server: uv_stream_t, client: uv_stream_t) -> Int:
        """Accept connection."""
        return external_call["uv_accept", Int](server, client)
    
    fn read_start(self, stream: uv_stream_t, alloc_cb: uv_alloc_cb, read_cb: uv_read_cb) -> Int:
        """Start reading from stream."""
        return external_call["uv_read_start", Int](stream, alloc_cb, read_cb)
    
    fn read_stop(self, stream: uv_stream_t) -> Int:
        """Stop reading from stream."""
        return external_call["uv_read_stop", Int](stream)
    
    fn write(self, stream: uv_stream_t, bufs: uv_buf_t, nbufs: Int) -> Int:
        """Write to stream."""
        return external_call["uv_write", Int](stream, bufs, nbufs)
    
    fn close(self, handle: uv_handle_t, close_cb: uv_close_cb) -> None:
        """Close handle."""
        external_call["uv_close", None](handle, close_cb)
    
    # ========================================================================
    # Address Functions
    # ========================================================================
    
    fn ip4_addr(self, ip: UnsafePointer[UInt8], port: Int, addr: UnsafePointer[NoneType]) -> Int:
        """Create IPv4 address."""
        return external_call["uv_ip4_addr", Int](ip, port, addr)
    
    fn ip6_addr(self, ip: UnsafePointer[UInt8], port: Int, addr: UnsafePointer[NoneType]) -> Int:
        """Create IPv6 address."""
        return external_call["uv_ip6_addr", Int](ip, port, addr)
    
    # ========================================================================
    # Error Handling
    # ========================================================================
    
    fn strerror(self, err: Int) -> UnsafePointer[UInt8]:
        """Get error string."""
        return external_call["uv_strerror", UnsafePointer[UInt8]](err)
    
    fn err_name(self, err: Int) -> UnsafePointer[UInt8]:
        """Get error name."""
        return external_call["uv_err_name", UnsafePointer[UInt8]](err)


# ============================================================================
# RAII Wrappers for Safety
# ============================================================================

struct UVLoop:
    """RAII wrapper for uv_loop_t."""
    
    var loop: uv_loop_t
    var lib: LibUV
    var initialized: Bool
    
    fn __init__(inout self) raises:
        """Create and initialize event loop."""
        self.lib = LibUV()
        self.loop = UnsafePointer[NoneType].alloc(1)
        let result = self.lib.loop_init(self.loop)
        if result < 0:
            raise Error("Failed to initialize libuv loop")
        self.initialized = True
    
    fn run(self, mode: Int = UV_RUN_DEFAULT) -> Int:
        """Run event loop."""
        return self.lib.run(self.loop, mode)
    
    fn stop(self):
        """Stop event loop."""
        self.lib.stop(self.loop)
    
    fn __del__(owned self):
        """Clean up event loop."""
        if self.initialized:
            _ = self.lib.loop_close(self.loop)
            self.loop.free()


struct UVTcp:
    """RAII wrapper for uv_tcp_t."""
    
    var tcp: uv_tcp_t
    var lib: LibUV
    var initialized: Bool
    
    fn __init__(inout self, loop: UVLoop) raises:
        """Create and initialize TCP handle."""
        self.lib = LibUV()
        self.tcp = UnsafePointer[NoneType].alloc(1)
        let result = self.lib.tcp_init(loop.loop, self.tcp)
        if result < 0:
            raise Error("Failed to initialize TCP handle")
        self.initialized = True
    
    fn bind(self, ip: String, port: Int) raises:
        """Bind TCP socket to address."""
        var addr = UnsafePointer[NoneType].alloc(1)
        let ip_ptr = ip.unsafe_ptr()
        let result = self.lib.ip4_addr(ip_ptr, port, addr)
        if result < 0:
            addr.free()
            raise Error("Failed to create address")
        
        let bind_result = self.lib.tcp_bind(self.tcp, addr, 0)
        addr.free()
        
        if bind_result < 0:
            raise Error("Failed to bind TCP socket")
    
    fn listen(self, backlog: Int, callback: uv_connection_cb) raises:
        """Listen for connections."""
        let result = self.lib.listen(self.tcp, backlog, callback)
        if result < 0:
            raise Error("Failed to listen on TCP socket")
    
    fn __del__(owned self):
        """Clean up TCP handle."""
        if self.initialized:
            self.tcp.free()

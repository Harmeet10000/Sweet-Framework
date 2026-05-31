# libuv FFI Wrapper
# Provides safe Mojo bindings to libuv event loop and TCP sockets
#
# libuv documentation: https://docs.libuv.org/en/v1.x/

from sweet.core.error import Error
from std.ffi import OwnedDLHandle, external_call
from std.memory import UnsafePointer, alloc

# ============================================================================
# libuv Types
# ============================================================================

struct UVBuf:
    var base: UnsafePointer[UInt8]
    var len: Int

alias uv_loop_t = UnsafePointer[NoneType, MutExternalOrigin]
alias uv_tcp_t = UnsafePointer[NoneType, MutExternalOrigin]
alias uv_stream_t = UnsafePointer[NoneType, MutExternalOrigin]
alias uv_handle_t = UnsafePointer[NoneType, MutExternalOrigin]
alias uv_buf_t = UnsafePointer[UVBuf, MutExternalOrigin]
alias uv_write_t = UnsafePointer[NoneType, MutExternalOrigin]

# Callback types
alias uv_alloc_cb = def(uv_handle_t, Int, uv_buf_t) -> None
alias uv_read_cb = def(uv_stream_t, Int, uv_buf_t) -> None
alias uv_connection_cb = def(uv_stream_t, Int) -> None
alias uv_write_cb = def(uv_write_t, Int) -> None
alias uv_close_cb = def(uv_handle_t) -> None

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
    
    var handle: OwnedDLHandle
    
    def __init__(out self) raises:
        """Load libuv shared library."""
        # Try different library names based on platform
        try:
            self.handle = OwnedDLHandle("libuv.so.1")  # Linux
        except:
            try:
                self.handle = OwnedDLHandle("libuv.1.dylib")  # macOS
            except:
                self.handle = OwnedDLHandle("libuv.dll")  # Windows
    
    # ========================================================================
    # Event Loop Functions
    # ========================================================================
    
    def loop_init(self, loop: uv_loop_t) -> Int:
        """Initialize event loop."""
        return external_call["uv_loop_init", Int](loop)
    
    def loop_close(self, loop: uv_loop_t) -> Int:
        """Close event loop."""
        return external_call["uv_loop_close", Int](loop)
    
    def run(self, loop: uv_loop_t, mode: Int) -> Int:
        """Run event loop."""
        return external_call["uv_run", Int](loop, mode)
    
    def stop(self, loop: uv_loop_t) -> None:
        """Stop event loop."""
        external_call["uv_stop", None](loop)
    
    # ========================================================================
    # TCP Functions
    # ========================================================================
    
    def tcp_init(self, loop: uv_loop_t, tcp: uv_tcp_t) -> Int:
        """Initialize TCP handle."""
        return external_call["uv_tcp_init", Int](loop, tcp)
    
    def tcp_bind(self, tcp: uv_tcp_t, addr: UnsafePointer[NoneType], flags: Int) -> Int:
        """Bind TCP socket to address."""
        return external_call["uv_tcp_bind", Int](tcp, addr, flags)
    
    def listen(self, stream: uv_stream_t, backlog: Int, cb: uv_connection_cb) -> Int:
        """Listen for connections."""
        return external_call["uv_listen", Int](stream, backlog, cb)
    
    def accept(self, server: uv_stream_t, client: uv_stream_t) -> Int:
        """Accept connection."""
        return external_call["uv_accept", Int](server, client)
    
    def read_start(self, stream: uv_stream_t, alloc_cb: uv_alloc_cb, read_cb: uv_read_cb) -> Int:
        """Start reading from stream."""
        return external_call["uv_read_start", Int](stream, alloc_cb, read_cb)
    
    def read_stop(self, stream: uv_stream_t) -> Int:
        """Stop reading from stream."""
        return external_call["uv_read_stop", Int](stream)
    
    def write(self, req: uv_write_t, stream: uv_stream_t, bufs: uv_buf_t, nbufs: Int, cb: uv_write_cb) -> Int:
        """Write to stream."""
        return external_call["uv_write", Int](req, stream, bufs, nbufs, cb)
    
    def close(self, handle: uv_handle_t, close_cb: uv_close_cb) -> None:
        """Close handle."""
        external_call["uv_close", None](handle, close_cb)
    
    # ========================================================================
    # Address Functions
    # ========================================================================
    
    def ip4_addr(self, ip: UnsafePointer[UInt8, MutExternalOrigin], port: Int, addr: UnsafePointer[NoneType, MutExternalOrigin]) -> Int:
        """Create IPv4 address."""
        return external_call["uv_ip4_addr", Int](ip, port, addr)
    
    def ip6_addr(self, ip: UnsafePointer[UInt8, MutExternalOrigin], port: Int, addr: UnsafePointer[NoneType, MutExternalOrigin]) -> Int:
        """Create IPv6 address."""
        return external_call["uv_ip6_addr", Int](ip, port, addr)
    
    # ========================================================================
    # Error Handling
    # ========================================================================
    
    def strerror(self, err: Int) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Get error string."""
        return external_call["uv_strerror", UnsafePointer[UInt8, MutExternalOrigin]](err)
    
    def err_name(self, err: Int) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Get error name."""
        return external_call["uv_err_name", UnsafePointer[UInt8, MutExternalOrigin]](err)


# ============================================================================
# RAII Wrappers for Safety
# ============================================================================

struct UVLoop:
    """RAII wrapper for uv_loop_t."""
    
    var loop: uv_loop_t
    var lib: LibUV
    var initialized: Bool
    
    def __init__(out self) raises:
        """Create and initialize event loop."""
        self.lib = LibUV()
        self.loop = alloc[NoneType](1)
        var result = self.lib.loop_init(self.loop)
        if result < 0:
            raise Error("Failed to initialize libuv loop")
        self.initialized = True
    
    def run(self, mode: Int = UV_RUN_DEFAULT) -> Int:
        """Run event loop."""
        return self.lib.run(self.loop, mode)
    
    def stop(self):
        """Stop event loop."""
        self.lib.stop(self.loop)
    
    def __del__(deinit self):
        """Clean up event loop."""
        if self.initialized:
            _ = self.lib.loop_close(self.loop)
            self.loop.free()


struct UVTcp:
    """RAII wrapper for uv_tcp_t."""
    
    var tcp: uv_tcp_t
    var lib: LibUV
    var initialized: Bool
    var write_buffer: Optional[uv_buf_t]
    var write_response: Optional[String]
    
    def __init__(out self, loop: UVLoop) raises:
        """Create and initialize TCP handle."""
        self.lib = LibUV()
        self.tcp = alloc[NoneType](1)
        self.write_buffer = None
        self.write_response = None
        var result = self.lib.tcp_init(loop.loop, self.tcp)
        if result < 0:
            raise Error("Failed to initialize TCP handle")
        self.initialized = True
    
    def bind(self, ip: String, port: Int) raises:
        """Bind TCP socket to address."""
        var addr = alloc[NoneType](1)
        var ip_ptr = ip.unsafe_ptr()
        var result = self.lib.ip4_addr(ip_ptr, port, addr)
        if result < 0:
            addr.free()
            raise Error("Failed to create address")
        
        var bind_result = self.lib.tcp_bind(self.tcp, addr, 0)
        addr.free()
        
        if bind_result < 0:
            raise Error("Failed to bind TCP socket")
    
    def listen(self, backlog: Int, callback: uv_connection_cb) raises:
        """Listen for connections."""
        var result = self.lib.listen(self.tcp, backlog, callback)
        if result < 0:
            raise Error("Failed to listen on TCP socket")

    def accept_from(self, server: UVTcp) raises:
        """Accept a new connection from a listening server."""
        var result = self.lib.accept(server.tcp, self.tcp)
        if result < 0:
            raise Error("Failed to accept TCP connection")

    def read_start(self, alloc_cb: uv_alloc_cb, read_cb: uv_read_cb) raises:
        """Start reading from this TCP stream."""
        var result = self.lib.read_start(self.tcp, alloc_cb, read_cb)
        if result < 0:
            raise Error("Failed to start reading from TCP stream")

    def read_stop(self) raises:
        """Stop reading from this TCP stream."""
        var result = self.lib.read_stop(self.tcp)
        if result < 0:
            raise Error("Failed to stop reading from TCP stream")

    def write_string(mut self, response: String, callback: uv_write_cb) raises:
        """Write a string response to this TCP stream."""
        var req = alloc[NoneType](1)
        var buf = alloc[UVBuf](1)
        self.write_response = response
        buf[].base = self.write_response.value().unsafe_ptr()
        buf[].len = len(self.write_response.value())
        self.write_buffer = buf

        var result = self.lib.write(req, self.tcp, buf, 1, callback)
        if result < 0:
            self.finish_write()
            req.free()
            raise Error("Failed to write to TCP stream")

    def finish_write(mut self):
        """Release retained state for the current write."""
        if self.write_buffer is not None:
            self.write_buffer.value().free()
            self.write_buffer = None
        self.write_response = None

    def __del__(deinit self):
        """Clean up TCP handle."""
        if self.write_buffer is not None:
            self.write_buffer.value().free()
        if self.initialized:
            self.tcp.free()

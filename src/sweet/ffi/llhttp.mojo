# llhttp FFI Wrapper
# Provides safe Mojo bindings to llhttp HTTP parser
#
# llhttp documentation: https://github.com/nodejs/llhttp

from sweet.core.error import Error
from std.ffi import OwnedDLHandle, external_call
from std.memory import UnsafePointer, alloc

# ============================================================================
# llhttp Types
# ============================================================================

alias llhttp_t = UnsafePointer[NoneType, MutExternalOrigin]
alias llhttp_settings_t = UnsafePointer[NoneType, MutExternalOrigin]

# HTTP Methods
alias HTTP_GET = 1
alias HTTP_POST = 3
alias HTTP_PUT = 4
alias HTTP_DELETE = 5
alias HTTP_PATCH = 28

# Parser Types
alias HTTP_REQUEST = 0
alias HTTP_RESPONSE = 1
alias HTTP_BOTH = 2

# ============================================================================
# llhttp FFI Functions
# ============================================================================

struct LLHttp:
    """Safe wrapper around llhttp library."""
    
    var handle: OwnedDLHandle
    var llhttp_init_fn: def(llhttp_t, Int, llhttp_settings_t) abi("C") -> None
    var llhttp_execute_fn: def(llhttp_t, UnsafePointer[UInt8, _], Int) abi("C") -> Int
    var llhttp_get_errno_fn: def(llhttp_t) abi("C") -> Int
    var llhttp_get_error_reason_fn: def(llhttp_t) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]
    var llhttp_get_method_fn: def(llhttp_t) abi("C") -> Int
    var llhttp_get_status_code_fn: def(llhttp_t) abi("C") -> Int
    var llhttp_get_http_major_fn: def(llhttp_t) abi("C") -> Int
    var llhttp_get_http_minor_fn: def(llhttp_t) abi("C") -> Int
    var llhttp_reset_fn: def(llhttp_t) abi("C") -> None
    var llhttp_settings_init_fn: def(llhttp_settings_t) abi("C") -> None
    
    def __init__(out self) raises:
        """Load llhttp shared library."""
        try:
            self.handle = OwnedDLHandle("vendor/llhttp/build/libllhttp.so")
        except:
            try:
                self.handle = OwnedDLHandle("vendor/llhttp/build/libllhttp.dylib")
            except:
                raise Error("Failed to load llhttp library")
        self.llhttp_init_fn = self.handle.get_function[def(llhttp_t, Int, llhttp_settings_t) abi("C") -> None]("llhttp_init")
        self.llhttp_execute_fn = self.handle.get_function[def(llhttp_t, UnsafePointer[UInt8, _], Int) abi("C") -> Int]("llhttp_execute")
        self.llhttp_get_errno_fn = self.handle.get_function[def(llhttp_t) abi("C") -> Int]("llhttp_get_errno")
        self.llhttp_get_error_reason_fn = self.handle.get_function[def(llhttp_t) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]]("llhttp_get_error_reason")
        self.llhttp_get_method_fn = self.handle.get_function[def(llhttp_t) abi("C") -> Int]("llhttp_get_method")
        self.llhttp_get_status_code_fn = self.handle.get_function[def(llhttp_t) abi("C") -> Int]("llhttp_get_status_code")
        self.llhttp_get_http_major_fn = self.handle.get_function[def(llhttp_t) abi("C") -> Int]("llhttp_get_http_major")
        self.llhttp_get_http_minor_fn = self.handle.get_function[def(llhttp_t) abi("C") -> Int]("llhttp_get_http_minor")
        self.llhttp_reset_fn = self.handle.get_function[def(llhttp_t) abi("C") -> None]("llhttp_reset")
        self.llhttp_settings_init_fn = self.handle.get_function[def(llhttp_settings_t) abi("C") -> None]("llhttp_settings_init")
    
    def init(self, parser: llhttp_t, type: Int, settings: llhttp_settings_t) -> None:
        """Initialize HTTP parser."""
        self.llhttp_init_fn(parser, type, settings)
    
    def execute(self, parser: llhttp_t, data: UnsafePointer[UInt8, _], len: Int) -> Int:
        """Execute HTTP parser on data."""
        return self.llhttp_execute_fn(parser, data, len)
    
    def get_errno(self, parser: llhttp_t) -> Int:
        """Get parser error code."""
        return self.llhttp_get_errno_fn(parser)
    
    def get_error_reason(self, parser: llhttp_t) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Get parser error reason."""
        return self.llhttp_get_error_reason_fn(parser)
    
    def get_method(self, parser: llhttp_t) -> Int:
        """Get HTTP method."""
        return self.llhttp_get_method_fn(parser)
    
    def get_status_code(self, parser: llhttp_t) -> Int:
        """Get HTTP status code."""
        return self.llhttp_get_status_code_fn(parser)
    
    def get_http_major(self, parser: llhttp_t) -> Int:
        """Get HTTP major version."""
        return self.llhttp_get_http_major_fn(parser)
    
    def get_http_minor(self, parser: llhttp_t) -> Int:
        """Get HTTP minor version."""
        return self.llhttp_get_http_minor_fn(parser)
    
    def reset(self, parser: llhttp_t) -> None:
        """Reset parser."""
        self.llhttp_reset_fn(parser)
    
    def settings_init(self, settings: llhttp_settings_t) -> None:
        """Initialize parser settings."""
        self.llhttp_settings_init_fn(settings)


# ============================================================================
# RAII Wrapper
# ============================================================================

struct HttpParser:
    """RAII wrapper for llhttp parser."""
    
    var parser: llhttp_t
    var settings: llhttp_settings_t
    var lib: LLHttp
    var initialized: Bool
    
    def __init__(out self, type: Int = HTTP_REQUEST) raises:
        """Create and initialize HTTP parser."""
        self.lib = LLHttp()
        self.parser = alloc[NoneType](1)
        self.settings = alloc[NoneType](1)
        
        self.lib.settings_init(self.settings)
        self.lib.init(self.parser, type, self.settings)
        self.initialized = True
    
    def parse(self, data: UnsafePointer[UInt8, _], length: Int) raises -> Int:
        """Parse HTTP data."""
        var result = self.lib.execute(self.parser, data, length)
        
        if result != length:
            var errno = self.lib.get_errno(self.parser)
            if errno != 0:
                var reason_ptr = self.lib.get_error_reason(self.parser)
                # Convert C string to Mojo String
                _ = reason_ptr
                raise Error("HTTP parse error")
        
        return result
    
    def get_method(self) -> Int:
        """Get parsed HTTP method."""
        return self.lib.get_method(self.parser)
    
    def get_version_major(self) -> Int:
        """Get parsed HTTP major version."""
        return self.lib.get_http_major(self.parser)

    def get_version_minor(self) -> Int:
        """Get parsed HTTP minor version."""
        return self.lib.get_http_minor(self.parser)
    
    def reset(self):
        """Reset parser for reuse."""
        self.lib.reset(self.parser)
    
    def __del__(deinit self):
        """Clean up parser."""
        if self.initialized:
            self.parser.free()
            self.settings.free()

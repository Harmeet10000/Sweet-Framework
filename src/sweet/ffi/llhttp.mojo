# llhttp FFI Wrapper
# Provides safe Mojo bindings to llhttp HTTP parser
#
# llhttp documentation: https://github.com/nodejs/llhttp

from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

# ============================================================================
# llhttp Types
# ============================================================================

alias llhttp_t = UnsafePointer[NoneType]
alias llhttp_settings_t = UnsafePointer[NoneType]

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
    
    var handle: DLHandle
    
    fn __init__(inout self) raises:
        """Load llhttp shared library."""
        try:
            self.handle = DLHandle("vendor/llhttp/build/libllhttp.so")
        except:
            try:
                self.handle = DLHandle("vendor/llhttp/build/libllhttp.dylib")
            except:
                raise Error("Failed to load llhttp library")
    
    fn init(self, parser: llhttp_t, type: Int, settings: llhttp_settings_t) -> None:
        """Initialize HTTP parser."""
        external_call["llhttp_init", None](parser, type, settings)
    
    fn execute(self, parser: llhttp_t, data: UnsafePointer[UInt8], len: Int) -> Int:
        """Execute HTTP parser on data."""
        return external_call["llhttp_execute", Int](parser, data, len)
    
    fn get_errno(self, parser: llhttp_t) -> Int:
        """Get parser error code."""
        return external_call["llhttp_get_errno", Int](parser)
    
    fn get_error_reason(self, parser: llhttp_t) -> UnsafePointer[UInt8]:
        """Get parser error reason."""
        return external_call["llhttp_get_error_reason", UnsafePointer[UInt8]](parser)
    
    fn get_method(self, parser: llhttp_t) -> Int:
        """Get HTTP method."""
        return external_call["llhttp_get_method", Int](parser)
    
    fn get_status_code(self, parser: llhttp_t) -> Int:
        """Get HTTP status code."""
        return external_call["llhttp_get_status_code", Int](parser)
    
    fn get_http_major(self, parser: llhttp_t) -> Int:
        """Get HTTP major version."""
        return external_call["llhttp_get_http_major", Int](parser)
    
    fn get_http_minor(self, parser: llhttp_t) -> Int:
        """Get HTTP minor version."""
        return external_call["llhttp_get_http_minor", Int](parser)
    
    fn reset(self, parser: llhttp_t) -> None:
        """Reset parser."""
        external_call["llhttp_reset", None](parser)
    
    fn settings_init(self, settings: llhttp_settings_t) -> None:
        """Initialize parser settings."""
        external_call["llhttp_settings_init", None](settings)


# ============================================================================
# RAII Wrapper
# ============================================================================

struct HttpParser:
    """RAII wrapper for llhttp parser."""
    
    var parser: llhttp_t
    var settings: llhttp_settings_t
    var lib: LLHttp
    var initialized: Bool
    
    fn __init__(inout self, type: Int = HTTP_REQUEST) raises:
        """Create and initialize HTTP parser."""
        self.lib = LLHttp()
        self.parser = UnsafePointer[NoneType].alloc(1)
        self.settings = UnsafePointer[NoneType].alloc(1)
        
        self.lib.settings_init(self.settings)
        self.lib.init(self.parser, type, self.settings)
        self.initialized = True
    
    fn parse(self, data: UnsafePointer[UInt8], length: Int) raises -> Int:
        """Parse HTTP data."""
        let result = self.lib.execute(self.parser, data, length)
        
        if result != length:
            let errno = self.lib.get_errno(self.parser)
            if errno != 0:
                let reason_ptr = self.lib.get_error_reason(self.parser)
                # Convert C string to Mojo String
                raise Error("HTTP parse error")
        
        return result
    
    fn get_method(self) -> Int:
        """Get parsed HTTP method."""
        return self.lib.get_method(self.parser)
    
    fn get_version(self) -> (Int, Int):
        """Get parsed HTTP version."""
        let major = self.lib.get_http_major(self.parser)
        let minor = self.lib.get_http_minor(self.parser)
        return (major, minor)
    
    fn reset(self):
        """Reset parser for reuse."""
        self.lib.reset(self.parser)
    
    fn __del__(owned self):
        """Clean up parser."""
        if self.initialized:
            self.parser.free()
            self.settings.free()

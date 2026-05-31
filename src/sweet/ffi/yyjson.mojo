# yyjson FFI Wrapper
# Provides safe Mojo bindings to yyjson JSON parser
#
# yyjson documentation: https://github.com/ibireme/yyjson

from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

# ============================================================================
# yyjson Types
# ============================================================================

alias yyjson_doc = UnsafePointer[NoneType]
alias yyjson_val = UnsafePointer[NoneType]
alias yyjson_mut_doc = UnsafePointer[NoneType]
alias yyjson_mut_val = UnsafePointer[NoneType]

# Read flags
alias YYJSON_READ_NOFLAG = 0
alias YYJSON_READ_INSITU = 1 << 0
alias YYJSON_READ_STOP_WHEN_DONE = 1 << 1
alias YYJSON_READ_ALLOW_TRAILING_COMMAS = 1 << 2
alias YYJSON_READ_ALLOW_COMMENTS = 1 << 3
alias YYJSON_READ_ALLOW_INF_AND_NAN = 1 << 4

# Write flags
alias YYJSON_WRITE_NOFLAG = 0
alias YYJSON_WRITE_PRETTY = 1 << 0
alias YYJSON_WRITE_ESCAPE_UNICODE = 1 << 1
alias YYJSON_WRITE_ESCAPE_SLASHES = 1 << 2
alias YYJSON_WRITE_ALLOW_INF_AND_NAN = 1 << 3

# ============================================================================
# yyjson FFI Functions
# ============================================================================

struct YYJson:
    """Safe wrapper around yyjson library."""
    
    var handle: DLHandle
    
    fn __init__(inout self) raises:
        """Load yyjson shared library."""
        try:
            self.handle = DLHandle("vendor/yyjson/build/libyyjson.so")
        except:
            try:
                self.handle = DLHandle("vendor/yyjson/build/libyyjson.dylib")
            except:
                raise Error("Failed to load yyjson library")
    
    # ========================================================================
    # Read Functions
    # ========================================================================
    
    fn read(self, dat: UnsafePointer[UInt8], len: Int, flg: Int) -> yyjson_doc:
        """Read JSON from string."""
        return external_call["yyjson_read", yyjson_doc](dat, len, flg)
    
    fn doc_get_root(self, doc: yyjson_doc) -> yyjson_val:
        """Get root value from document."""
        return external_call["yyjson_doc_get_root", yyjson_val](doc)
    
    fn doc_free(self, doc: yyjson_doc) -> None:
        """Free JSON document."""
        external_call["yyjson_doc_free", None](doc)
    
    # ========================================================================
    # Value Type Checking
    # ========================================================================
    
    fn is_null(self, val: yyjson_val) -> Bool:
        """Check if value is null."""
        return external_call["yyjson_is_null", Bool](val)
    
    fn is_bool(self, val: yyjson_val) -> Bool:
        """Check if value is boolean."""
        return external_call["yyjson_is_bool", Bool](val)
    
    fn is_num(self, val: yyjson_val) -> Bool:
        """Check if value is number."""
        return external_call["yyjson_is_num", Bool](val)
    
    fn is_str(self, val: yyjson_val) -> Bool:
        """Check if value is string."""
        return external_call["yyjson_is_str", Bool](val)
    
    fn is_arr(self, val: yyjson_val) -> Bool:
        """Check if value is array."""
        return external_call["yyjson_is_arr", Bool](val)
    
    fn is_obj(self, val: yyjson_val) -> Bool:
        """Check if value is object."""
        return external_call["yyjson_is_obj", Bool](val)
    
    # ========================================================================
    # Value Getters
    # ========================================================================
    
    fn get_bool(self, val: yyjson_val) -> Bool:
        """Get boolean value."""
        return external_call["yyjson_get_bool", Bool](val)
    
    fn get_int(self, val: yyjson_val) -> Int64:
        """Get integer value."""
        return external_call["yyjson_get_int", Int64](val)
    
    fn get_real(self, val: yyjson_val) -> Float64:
        """Get float value."""
        return external_call["yyjson_get_real", Float64](val)
    
    fn get_str(self, val: yyjson_val) -> UnsafePointer[UInt8]:
        """Get string value."""
        return external_call["yyjson_get_str", UnsafePointer[UInt8]](val)
    
    fn get_len(self, val: yyjson_val) -> Int:
        """Get string/array/object length."""
        return external_call["yyjson_get_len", Int](val)
    
    # ========================================================================
    # Object Functions
    # ========================================================================
    
    fn obj_get(self, obj: yyjson_val, key: UnsafePointer[UInt8]) -> yyjson_val:
        """Get value from object by key."""
        return external_call["yyjson_obj_get", yyjson_val](obj, key)
    
    # ========================================================================
    # Write Functions
    # ========================================================================
    
    fn write(self, val: yyjson_val, flg: Int, len: UnsafePointer[Int]) -> UnsafePointer[UInt8]:
        """Write JSON to string."""
        return external_call["yyjson_write", UnsafePointer[UInt8]](val, flg, len)
    
    fn free(self, str: UnsafePointer[UInt8]) -> None:
        """Free JSON string."""
        external_call["yyjson_free", None](str)


# ============================================================================
# RAII Wrapper
# ============================================================================

struct JsonDocument:
    """RAII wrapper for yyjson document."""
    
    var doc: yyjson_doc
    var lib: YYJson
    var valid: Bool
    
    fn __init__(inout self, json_str: String, flags: Int = YYJSON_READ_NOFLAG) raises:
        """Parse JSON string."""
        self.lib = YYJson()
        let data = json_str.unsafe_ptr()
        let length = len(json_str)
        
        self.doc = self.lib.read(data, length, flags)
        
        if self.doc == UnsafePointer[NoneType]():
            self.valid = False
            raise Error("Failed to parse JSON")
        
        self.valid = True
    
    fn get_root(self) -> yyjson_val:
        """Get root value."""
        return self.lib.doc_get_root(self.doc)
    
    fn __del__(owned self):
        """Clean up document."""
        if self.valid:
            self.lib.doc_free(self.doc)

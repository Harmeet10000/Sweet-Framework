# yyjson FFI Wrapper
# Provides safe Mojo bindings to yyjson JSON parser
#
# yyjson documentation: https://github.com/ibireme/yyjson

from sweet.core.error import Error
from std.ffi import OwnedDLHandle, external_call
from std.memory import UnsafePointer

# ============================================================================
# yyjson Types
# ============================================================================

alias yyjson_doc = UnsafePointer[NoneType, MutExternalOrigin]
alias yyjson_val = UnsafePointer[NoneType, MutExternalOrigin]
alias yyjson_mut_doc = UnsafePointer[NoneType, MutExternalOrigin]
alias yyjson_mut_val = UnsafePointer[NoneType, MutExternalOrigin]

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
    
    var handle: OwnedDLHandle
    var yyjson_read_fn: def(UnsafePointer[UInt8, _], Int, Int) abi("C") -> yyjson_doc
    var yyjson_doc_get_root_fn: def(yyjson_doc) abi("C") -> yyjson_val
    var yyjson_doc_free_fn: def(yyjson_doc) abi("C") -> None
    var yyjson_is_null_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_is_bool_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_is_num_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_is_str_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_is_arr_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_is_obj_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_get_bool_fn: def(yyjson_val) abi("C") -> Bool
    var yyjson_get_int_fn: def(yyjson_val) abi("C") -> Int64
    var yyjson_get_real_fn: def(yyjson_val) abi("C") -> Float64
    var yyjson_get_str_fn: def(yyjson_val) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]
    var yyjson_get_len_fn: def(yyjson_val) abi("C") -> Int
    var yyjson_obj_get_fn: def(yyjson_val, UnsafePointer[UInt8, _]) abi("C") -> yyjson_val
    var yyjson_write_fn: def(yyjson_val, Int, UnsafePointer[Int, MutExternalOrigin]) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]
    var yyjson_free_fn: def(UnsafePointer[UInt8, MutExternalOrigin]) abi("C") -> None
    
    def __init__(out self) raises:
        """Load yyjson shared library."""
        try:
            self.handle = OwnedDLHandle("vendor/yyjson/build/libyyjson.so")
        except:
            try:
                self.handle = OwnedDLHandle("vendor/yyjson/build/libyyjson.dylib")
            except:
                raise Error("Failed to load yyjson library")
        self.yyjson_read_fn = self.handle.get_function[def(UnsafePointer[UInt8, _], Int, Int) abi("C") -> yyjson_doc]("yyjson_read")
        self.yyjson_doc_get_root_fn = self.handle.get_function[def(yyjson_doc) abi("C") -> yyjson_val]("yyjson_doc_get_root")
        self.yyjson_doc_free_fn = self.handle.get_function[def(yyjson_doc) abi("C") -> None]("yyjson_doc_free")
        self.yyjson_is_null_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_null")
        self.yyjson_is_bool_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_bool")
        self.yyjson_is_num_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_num")
        self.yyjson_is_str_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_str")
        self.yyjson_is_arr_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_arr")
        self.yyjson_is_obj_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_is_obj")
        self.yyjson_get_bool_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Bool]("yyjson_get_bool")
        self.yyjson_get_int_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Int64]("yyjson_get_int")
        self.yyjson_get_real_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Float64]("yyjson_get_real")
        self.yyjson_get_str_fn = self.handle.get_function[def(yyjson_val) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]]("yyjson_get_str")
        self.yyjson_get_len_fn = self.handle.get_function[def(yyjson_val) abi("C") -> Int]("yyjson_get_len")
        self.yyjson_obj_get_fn = self.handle.get_function[def(yyjson_val, UnsafePointer[UInt8, _]) abi("C") -> yyjson_val]("yyjson_obj_get")
        self.yyjson_write_fn = self.handle.get_function[def(yyjson_val, Int, UnsafePointer[Int, MutExternalOrigin]) abi("C") -> UnsafePointer[UInt8, MutExternalOrigin]]("yyjson_write")
        self.yyjson_free_fn = self.handle.get_function[def(UnsafePointer[UInt8, MutExternalOrigin]) abi("C") -> None]("yyjson_free")
    
    # ========================================================================
    # Read Functions
    # ========================================================================
    
    def read(self, dat: UnsafePointer[UInt8, _], len: Int, flg: Int) -> yyjson_doc:
        """Read JSON from string."""
        return self.yyjson_read_fn(dat, len, flg)
    
    def doc_get_root(self, doc: yyjson_doc) -> yyjson_val:
        """Get root value from document."""
        return self.yyjson_doc_get_root_fn(doc)
    
    def doc_free(self, doc: yyjson_doc) -> None:
        """Free JSON document."""
        self.yyjson_doc_free_fn(doc)
    
    # ========================================================================
    # Value Type Checking
    # ========================================================================
    
    def is_null(self, val: yyjson_val) -> Bool:
        """Check if value is null."""
        return self.yyjson_is_null_fn(val)
    
    def is_bool(self, val: yyjson_val) -> Bool:
        """Check if value is boolean."""
        return self.yyjson_is_bool_fn(val)
    
    def is_num(self, val: yyjson_val) -> Bool:
        """Check if value is number."""
        return self.yyjson_is_num_fn(val)
    
    def is_str(self, val: yyjson_val) -> Bool:
        """Check if value is string."""
        return self.yyjson_is_str_fn(val)
    
    def is_arr(self, val: yyjson_val) -> Bool:
        """Check if value is array."""
        return self.yyjson_is_arr_fn(val)
    
    def is_obj(self, val: yyjson_val) -> Bool:
        """Check if value is object."""
        return self.yyjson_is_obj_fn(val)
    
    # ========================================================================
    # Value Getters
    # ========================================================================
    
    def get_bool(self, val: yyjson_val) -> Bool:
        """Get boolean value."""
        return self.yyjson_get_bool_fn(val)
    
    def get_int(self, val: yyjson_val) -> Int64:
        """Get integer value."""
        return self.yyjson_get_int_fn(val)
    
    def get_real(self, val: yyjson_val) -> Float64:
        """Get float value."""
        return self.yyjson_get_real_fn(val)
    
    def get_str(self, val: yyjson_val) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Get string value."""
        return self.yyjson_get_str_fn(val)
    
    def get_len(self, val: yyjson_val) -> Int:
        """Get string/array/object length."""
        return self.yyjson_get_len_fn(val)
    
    # ========================================================================
    # Object Functions
    # ========================================================================
    
    def obj_get(self, obj: yyjson_val, key: UnsafePointer[UInt8, _]) -> yyjson_val:
        """Get value from object by key."""
        return self.yyjson_obj_get_fn(obj, key)
    
    # ========================================================================
    # Write Functions
    # ========================================================================
    
    def write(self, val: yyjson_val, flg: Int, len: UnsafePointer[Int, MutExternalOrigin]) -> UnsafePointer[UInt8, MutExternalOrigin]:
        """Write JSON to string."""
        return self.yyjson_write_fn(val, flg, len)
    
    def free(self, str: UnsafePointer[UInt8, MutExternalOrigin]) -> None:
        """Free JSON string."""
        self.yyjson_free_fn(str)


# ============================================================================
# RAII Wrapper
# ============================================================================

struct JsonDocument:
    """RAII wrapper for yyjson document."""
    
    var doc: yyjson_doc
    var lib: YYJson
    var valid: Bool
    
    def __init__(out self, json_str: String, flags: Int = YYJSON_READ_NOFLAG) raises:
        """Parse JSON string."""
        self.lib = YYJson()
        var data = json_str.unsafe_ptr()
        var length = len(json_str)
        
        self.doc = self.lib.read(data, length, flags)
        
        if self.doc == yyjson_doc():
            self.valid = False
            raise Error("Failed to parse JSON")
        
        self.valid = True
    
    def get_root(self) -> yyjson_val:
        """Get root value."""
        return self.lib.doc_get_root(self.doc)
    
    def __del__(deinit self):
        """Clean up document."""
        if self.valid:
            self.lib.doc_free(self.doc)

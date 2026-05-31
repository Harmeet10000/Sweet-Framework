# Error types used by the current FFI and HTTP server slice.

from std.io import Writer

comptime ErrorKind = Int
comptime ERROR_UNKNOWN = 0
comptime ERROR_IO = 1
comptime ERROR_PARSE = 2
comptime ERROR_NETWORK = 3

struct Error(Writable):
    var kind: ErrorKind
    var message: String

    def __init__(out self, message: String):
        self.kind = ERROR_UNKNOWN
        self.message = message

    def __init__(out self, kind: ErrorKind, message: String):
        self.kind = kind
        self.message = message

    def describe(self) -> String:
        return self.message

    def write_to(self, mut writer: Some[Writer]):
        writer.write(self.message)

# Next Steps Mojo Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Sweet's Week 2 FFI and server slice to current Mojo syntax and implement the first `NEXT-STEPS.md` items without a repo-wide rewrite.

**Architecture:** Keep the work scoped to the FFI wrappers, TCP/HTTP server path, request/response types, and the tests/examples that exercise them. Update deprecated Mojo syntax first, then fix only the minimum runtime issues needed to make the FFI validation path and week 2 entrypoints meaningfully runnable.

**Tech Stack:** Mojo, libuv, llhttp, yyjson, Sweet local tests/examples

---

## File Structure

- `src/sweet/ffi/libuv.mojo`: libuv loading, loop/tcp wrapper lifecycle, listen path.
- `src/sweet/ffi/llhttp.mojo`: llhttp loading, parser lifecycle, parse helpers.
- `src/sweet/ffi/yyjson.mojo`: yyjson loading, document lifecycle, parse helpers.
- `src/sweet/server/tcp.mojo`: minimal TCP server wrapper over `UVLoop` and `UVTcp`.
- `src/sweet/server/http.mojo`: minimal HTTP server wrapper over `TcpServer` and `HttpParser`.
- `src/sweet/http/request.mojo`: request value type used by the server path.
- `src/sweet/http/response.mojo`: response value type and formatting helpers.
- `tests/test_ffi_libuv.mojo`: libuv construction smoke tests.
- `tests/test_ffi_llhttp.mojo`: llhttp parse smoke tests.
- `tests/test_ffi_yyjson.mojo`: yyjson parse smoke tests.
- `examples/week2-tcp-server/main.mojo`: week 2 TCP entrypoint smoke example.
- `examples/week2-http-server/main.mojo`: week 2 HTTP entrypoint smoke example.

### Task 1: Migrate Request/Response Types To Current Mojo Syntax

**Files:**
- Modify: `src/sweet/http/request.mojo`
- Modify: `src/sweet/http/response.mojo`

- [ ] **Step 1: Update `HttpRequest` constructors and mutating methods to `def` syntax**

```mojo
struct HttpRequest:
    var method: String
    var path: String
    var headers: Dict[String, String]
    var body: String
    var version: (Int, Int)

    def __init__(out self):
        self.method = "GET"
        self.path = "/"
        self.headers = Dict[String, String]()
        self.body = ""
        self.version = (1, 1)

    def __init__(out self, method: String, path: String):
        self.method = method
        self.path = path
        self.headers = Dict[String, String]()
        self.body = ""
        self.version = (1, 1)

    def get_header(self, name: String) -> Optional[String]:
        if name in self.headers:
            return self.headers[name]
        return None

    def set_header(mut self, name: String, value: String):
        self.headers[name] = value
```

- [ ] **Step 2: Update `HttpResponse` to `def` syntax and `mut self` for mutating methods**

```mojo
struct HttpResponse:
    var status: Int
    var headers: Dict[String, String]
    var body: String

    def __init__(out self, status: Int = 200):
        self.status = status
        self.headers = Dict[String, String]()
        self.body = ""
        self.headers["Content-Type"] = "text/plain"
        self.headers["Server"] = "Sweet/0.1.0"

    def set_header(mut self, name: String, value: String):
        self.headers[name] = value

    def set_json(mut self, json: String):
        self.body = json
        self.headers["Content-Type"] = "application/json"

    def set_html(mut self, html: String):
        self.body = html
        self.headers["Content-Type"] = "text/html"

    def to_bytes(self) -> String:
        var result = "HTTP/1.1 " + String(self.status) + " " + self.status_text() + "\r\n"
        var content_length = len(self.body)
        result += "Content-Length: " + String(content_length) + "\r\n"
        for item in self.headers.items():
            result += item[].key + ": " + item[].value + "\r\n"
        result += "\r\n"
        result += self.body
        return result

    def status_text(self) -> String:
        if self.status == 200:
            return "OK"
        elif self.status == 201:
            return "Created"
        elif self.status == 204:
            return "No Content"
        elif self.status == 400:
            return "Bad Request"
        elif self.status == 404:
            return "Not Found"
        elif self.status == 500:
            return "Internal Server Error"
        else:
            return "Unknown"

    @staticmethod
    def error(status: Int, message: String) -> HttpResponse:
        var response = HttpResponse(status)
        response.body = message
        return response
```

- [ ] **Step 3: Add the remaining static helpers with matching syntax**

```mojo
    @staticmethod
    def ok(body: String) -> HttpResponse:
        var response = HttpResponse(200)
        response.body = body
        return response

    @staticmethod
    def json(data: String) -> HttpResponse:
        var response = HttpResponse(200)
        response.set_json(data)
        return response
```

- [ ] **Step 4: Read the files once after editing to verify no `fn` or `inout self` remains**

Run: inspect `src/sweet/http/request.mojo` and `src/sweet/http/response.mojo`
Expected: all methods use `def`; mutating methods use `mut self`; constructors use `out self`

### Task 2: Migrate And Stabilize The libuv Wrapper

**Files:**
- Modify: `src/sweet/ffi/libuv.mojo`
- Test: `tests/test_ffi_libuv.mojo`

- [ ] **Step 1: Add the missing error import and convert callback/type aliases away from `fn`**

```mojo
from sweet.core.error import Error
from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

alias uv_loop_t = UnsafePointer[NoneType]
alias uv_tcp_t = UnsafePointer[NoneType]
alias uv_stream_t = UnsafePointer[NoneType]
alias uv_handle_t = UnsafePointer[NoneType]
alias uv_buf_t = UnsafePointer[NoneType]

alias uv_alloc_cb = def(UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None
alias uv_read_cb = def(UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None
alias uv_connection_cb = def(UnsafePointer[NoneType], Int) -> None
alias uv_close_cb = def(UnsafePointer[NoneType]) -> None
```

- [ ] **Step 2: Convert `LibUV` methods to `def` syntax**

```mojo
struct LibUV:
    var handle: DLHandle

    def __init__(out self) raises:
        try:
            self.handle = DLHandle("libuv.so.1")
        except:
            try:
                self.handle = DLHandle("libuv.1.dylib")
            except:
                self.handle = DLHandle("libuv.dll")

    def loop_init(self, loop: uv_loop_t) -> Int:
        return external_call["uv_loop_init", Int](loop)

    def loop_close(self, loop: uv_loop_t) -> Int:
        return external_call["uv_loop_close", Int](loop)
```

- [ ] **Step 3: Convert `UVLoop` and `UVTcp` lifecycle methods to current syntax**

```mojo
struct UVLoop:
    var loop: uv_loop_t
    var lib: LibUV
    var initialized: Bool

    def __init__(out self) raises:
        self.lib = LibUV()
        self.loop = UnsafePointer[NoneType].alloc(1)
        let result = self.lib.loop_init(self.loop)
        if result < 0:
            raise Error("Failed to initialize libuv loop")
        self.initialized = True

    def run(self, mode: Int = UV_RUN_DEFAULT) -> Int:
        return self.lib.run(self.loop, mode)

    def stop(self):
        self.lib.stop(self.loop)

struct UVTcp:
    var tcp: uv_tcp_t
    var lib: LibUV
    var initialized: Bool

    def __init__(out self, loop: UVLoop) raises:
        self.lib = LibUV()
        self.tcp = UnsafePointer[NoneType].alloc(1)
        let result = self.lib.tcp_init(loop.loop, self.tcp)
        if result < 0:
            raise Error("Failed to initialize TCP handle")
        self.initialized = True
```

- [ ] **Step 4: Convert the libuv test file to `def` syntax**

```mojo
from sweet.ffi.libuv import LibUV, UVLoop, UVTcp

def test_libuv_load() raises:
    print("Testing libuv library loading...")
    let lib = LibUV()
    print("✓ libuv loaded successfully")

def test_event_loop_creation() raises:
    print("Testing event loop creation...")
    let loop = UVLoop()
    print("✓ Event loop created successfully")

def test_tcp_creation() raises:
    print("Testing TCP handle creation...")
    let loop = UVLoop()
    let tcp = UVTcp(loop)
    print("✓ TCP handle created successfully")

def main() raises:
    print("=== libuv FFI Tests ===\n")
    test_libuv_load()
    print()
    test_event_loop_creation()
    print()
    test_tcp_creation()
    print()
    print("=== All tests passed! ===")
```

- [ ] **Step 5: Run the libuv smoke test**

Run: `mojo run tests/test_ffi_libuv.mojo`
Expected: either PASS output from the three smoke checks or a concrete library/runtime blocker instead of syntax errors

### Task 3: Migrate And Stabilize The llhttp Wrapper

**Files:**
- Modify: `src/sweet/ffi/llhttp.mojo`
- Test: `tests/test_ffi_llhttp.mojo`

- [ ] **Step 1: Add the missing error import and convert `LLHttp` to current syntax**

```mojo
from sweet.core.error import Error
from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

struct LLHttp:
    var handle: DLHandle

    def __init__(out self) raises:
        try:
            self.handle = DLHandle("vendor/llhttp/build/libllhttp.so")
        except:
            try:
                self.handle = DLHandle("vendor/llhttp/build/libllhttp.dylib")
            except:
                raise Error("Failed to load llhttp library")

    def init(self, parser: llhttp_t, type: Int, settings: llhttp_settings_t) -> None:
        external_call["llhttp_init", None](parser, type, settings)
```

- [ ] **Step 2: Convert `HttpParser` lifecycle and helper methods to `def` syntax**

```mojo
struct HttpParser:
    var parser: llhttp_t
    var settings: llhttp_settings_t
    var lib: LLHttp
    var initialized: Bool

    def __init__(out self, type: Int = HTTP_REQUEST) raises:
        self.lib = LLHttp()
        self.parser = UnsafePointer[NoneType].alloc(1)
        self.settings = UnsafePointer[NoneType].alloc(1)
        self.lib.settings_init(self.settings)
        self.lib.init(self.parser, type, self.settings)
        self.initialized = True

    def parse(self, data: UnsafePointer[UInt8], length: Int) raises -> Int:
        let result = self.lib.execute(self.parser, data, length)
        if result != length:
            let errno = self.lib.get_errno(self.parser)
            if errno != 0:
                raise Error("HTTP parse error")
        return result
```

- [ ] **Step 3: Convert the llhttp test file to `def` syntax**

```mojo
from sweet.ffi.llhttp import LLHttp, HttpParser, HTTP_REQUEST, HTTP_GET

def test_llhttp_load() raises:
    print("Testing llhttp library loading...")
    let lib = LLHttp()
    print("✓ llhttp loaded successfully")

def test_parser_creation() raises:
    print("Testing HTTP parser creation...")
    let parser = HttpParser(HTTP_REQUEST)
    print("✓ HTTP parser created successfully")

def test_simple_request_parsing() raises:
    print("Testing simple HTTP request parsing...")
    let parser = HttpParser(HTTP_REQUEST)
    let request = "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n"
    let data = request.unsafe_ptr()
    let length = len(request)
    let result = parser.parse(data, length)
    print("✓ Parsed", result, "bytes")
    let method = parser.get_method()
    print("✓ Method:", method, "(expected", HTTP_GET, ")")
    let (major, minor) = parser.get_version()
    print("✓ HTTP version:", major, ".", minor)
```

- [ ] **Step 4: Run the llhttp smoke test**

Run: `mojo run tests/test_ffi_llhttp.mojo`
Expected: parser construction/parsing output or a concrete non-syntax llhttp blocker

### Task 4: Migrate And Stabilize The yyjson Wrapper

**Files:**
- Modify: `src/sweet/ffi/yyjson.mojo`
- Test: `tests/test_ffi_yyjson.mojo`

- [ ] **Step 1: Add the missing error import and convert `YYJson` methods to `def` syntax**

```mojo
from sweet.core.error import Error
from sys.ffi import DLHandle, external_call
from memory import UnsafePointer

struct YYJson:
    var handle: DLHandle

    def __init__(out self) raises:
        try:
            self.handle = DLHandle("vendor/yyjson/build/libyyjson.so")
        except:
            try:
                self.handle = DLHandle("vendor/yyjson/build/libyyjson.dylib")
            except:
                raise Error("Failed to load yyjson library")
```

- [ ] **Step 2: Convert `JsonDocument` lifecycle methods to current syntax**

```mojo
struct JsonDocument:
    var doc: yyjson_doc
    var lib: YYJson
    var valid: Bool

    def __init__(out self, json_str: String, flags: Int = YYJSON_READ_NOFLAG) raises:
        self.lib = YYJson()
        let data = json_str.unsafe_ptr()
        let length = len(json_str)
        self.doc = self.lib.read(data, length, flags)
        if self.doc == UnsafePointer[NoneType]():
            self.valid = False
            raise Error("Failed to parse JSON")
        self.valid = True

    def get_root(self) -> yyjson_val:
        return self.lib.doc_get_root(self.doc)
```

- [ ] **Step 3: Convert the yyjson test file to `def` syntax**

```mojo
from sweet.ffi.yyjson import YYJson, JsonDocument, YYJSON_READ_NOFLAG

def test_yyjson_load() raises:
    print("Testing yyjson library loading...")
    let lib = YYJson()
    print("✓ yyjson loaded successfully")

def test_json_parsing() raises:
    print("Testing JSON parsing...")
    let json_str = '{"name": "Sweet", "version": "0.1.0", "fast": true}'
    let doc = JsonDocument(json_str, YYJSON_READ_NOFLAG)
    print("✓ JSON parsed successfully")
    let root = doc.get_root()
    print("✓ Got root value")

def test_invalid_json() raises:
    print("Testing invalid JSON handling...")
    let invalid_json = '{"name": "Sweet", invalid}'
    try:
        let doc = JsonDocument(invalid_json, YYJSON_READ_NOFLAG)
        print("✗ Should have raised error for invalid JSON")
    except:
        print("✓ Correctly raised error for invalid JSON")
```

- [ ] **Step 4: Run the yyjson smoke test**

Run: `mojo run tests/test_ffi_yyjson.mojo`
Expected: document parsing output or a concrete non-syntax yyjson blocker

### Task 5: Migrate The TCP Server Slice And Add The First Listen Path

**Files:**
- Modify: `src/sweet/server/tcp.mojo`
- Modify: `examples/week2-tcp-server/main.mojo`

- [ ] **Step 1: Convert callback aliases and `TcpServer` methods to current syntax**

```mojo
from sweet.ffi.libuv import LibUV, UVLoop, UVTcp, uv_stream_t, uv_connection_cb
from memory import UnsafePointer

alias ConnectionHandler = def(UnsafePointer[NoneType]) -> None

struct TcpServer:
    var loop: UVLoop
    var tcp: UVTcp
    var host: String
    var port: Int
    var handler: Optional[ConnectionHandler]

    def __init__(out self, host: String, port: Int) raises:
        self.host = host
        self.port = port
        self.loop = UVLoop()
        self.tcp = UVTcp(self.loop)
        self.handler = None
        self.tcp.bind(host, port)
```

- [ ] **Step 2: Keep the first minimal listen path explicit instead of pretending to fully accept sockets**

```mojo
    def listen(mut self, handler: ConnectionHandler, backlog: Int = 128) raises:
        self.handler = handler

        def connection_callback(server: UnsafePointer[NoneType], status: Int):
            if status < 0:
                print("Connection error:", status)
                return
            print("New connection!")

        self.tcp.listen(backlog, connection_callback)

    def run(self) raises:
        print("TCP Server listening on", self.host + ":" + String(self.port))
        _ = self.loop.run()
```

- [ ] **Step 3: Convert the week 2 TCP example to `def` syntax**

```mojo
from sweet.server.tcp import TcpServer, create_echo_server

def main() raises:
    print("=== Week 2: TCP Server Example ===\n")
    print("Creating TCP server on 0.0.0.0:8000...")
    var server = create_echo_server("0.0.0.0", 8000)
    print("Starting server...")
    print("Test with: telnet localhost 8000")
    print("Press Ctrl+C to stop\n")
    server.run()
```

- [ ] **Step 4: Run the TCP example as a smoke test**

Run: `mojo run examples/week2-tcp-server/main.mojo`
Expected: server startup output or a concrete non-syntax runtime blocker

### Task 6: Migrate The HTTP Server Slice And Keep Routing Placeholder-Safe

**Files:**
- Modify: `src/sweet/server/http.mojo`
- Modify: `examples/week2-http-server/main.mojo`

- [ ] **Step 1: Convert route handler aliases and `HttpServer` methods to current syntax**

```mojo
from sweet.server.tcp import TcpServer
from sweet.ffi.llhttp import HttpParser, HTTP_REQUEST
from sweet.http.request import HttpRequest
from sweet.http.response import HttpResponse
from sweet.core.result import Result, Ok, Err
from sweet.core.error import Error, ErrorKind
from memory import UnsafePointer

alias RouteHandler = def(HttpRequest) raises -> Result[HttpResponse, Error]

struct HttpServer:
    var tcp_server: TcpServer
    var parser: HttpParser
    var routes: Dict[String, RouteHandler]

    def __init__(out self, host: String, port: Int) raises:
        self.tcp_server = TcpServer(host, port)
        self.parser = HttpParser(HTTP_REQUEST)
        self.routes = Dict[String, RouteHandler]()
```

- [ ] **Step 2: Keep request handling minimal and explicit**

```mojo
    def route(mut self, path: String, handler: RouteHandler) raises:
        self.routes[path] = handler

    def handle_request(mut self, data: UnsafePointer[UInt8], length: Int) raises -> HttpResponse:
        let parse_result = self.parser.parse(data, length)
        let method = self.parser.get_method()
        let (major, minor) = self.parser.get_version()
        let path = "/"

        if path in self.routes:
            let handler = self.routes[path]
            let request = HttpRequest()
            let result = handler(request)
            if result.is_ok():
                return result.unwrap()
            else:
                return HttpResponse.error(500, "Internal Server Error")
        else:
            return HttpResponse.error(404, "Not Found")
```

- [ ] **Step 3: Convert the server entrypoint and example to `def` syntax**

```mojo
def create_simple_server(host: String, port: Int) raises -> HttpServer:
    var server = HttpServer(host, port)

    def hello_handler(request: HttpRequest) raises -> Result[HttpResponse, Error]:
        var response = HttpResponse(200)
        response.body = "Hello from Sweet!"
        return Ok(response)

    server.route("/", hello_handler)
    return server
```

```mojo
from sweet.server.http import HttpServer, create_simple_server

def main() raises:
    print("=== Week 2: HTTP Server Example ===\n")
    print("Creating HTTP server on 0.0.0.0:8000...")
    var server = create_simple_server("0.0.0.0", 8000)
    print("Starting server...")
    print("Test with: curl http://localhost:8000/")
    print("Press Ctrl+C to stop\n")
    server.run()
```

- [ ] **Step 4: Run the HTTP example as a smoke test**

Run: `mojo run examples/week2-http-server/main.mojo`
Expected: startup output or a concrete non-syntax runtime blocker

## Self-Review

- Spec coverage: all scoped files, FFI validation, minimal TCP/HTTP path, and smoke verification are covered by Tasks 1-6.
- Placeholder scan: no TBD/TODO placeholders are left in the plan steps.
- Type consistency: `HttpRequest`, `HttpResponse`, `UVLoop`, `UVTcp`, `HttpParser`, `TcpServer`, and `HttpServer` names/signatures are consistent across tasks.

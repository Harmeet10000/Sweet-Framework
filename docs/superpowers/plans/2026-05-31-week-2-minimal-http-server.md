# Week 2 Minimal HTTP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first runnable Week 2 slice for Sweet by replacing the placeholder core modules and carrying the migrated TCP/HTTP path to a minimal static HTTP response loop.

**Architecture:** Keep the slice narrow and V1.0-scoped. First unblock compilation by implementing only the `Error` and `Result` primitives the existing FFI and HTTP code already imports. Then extend the libuv/TCP path just far enough to accept a connection, read raw request bytes, hand them to `HttpServer.handle_request()`, and write back one static response.

**Tech Stack:** Mojo, libuv, llhttp, yyjson, vendored llhttp build, Week 2 examples and FFI smoke tests

---

## File Structure

- `src/sweet/core/error.mojo`: minimal error kind constants plus an `Error` value type usable by `raise Error("...")` in the FFI wrappers and server path.
- `src/sweet/core/result.mojo`: minimal `Result[T, E]` container plus `Ok()` and `Err()` helpers for the current HTTP route flow.
- `src/sweet/core/__init__.mojo`: exports the new core primitives from one place.
- `src/sweet/core/types.mojo`: intentionally untouched unless the compile path proves it is required.
- `src/sweet/__init__.mojo`: intentionally untouched unless the compile path proves the Week 2 examples need top-level exports.
- `src/sweet/ffi/libuv.mojo`: low-level libuv aliases and RAII wrappers; this slice adds only the missing read/write helpers needed by `TcpServer`.
- `src/sweet/ffi/llhttp.mojo`: existing parser wrapper used by `HttpServer.handle_request()`; only patch if the new core types surface a compile issue.
- `src/sweet/http/request.mojo`: request value type already migrated to current syntax; reused as the narrow request model.
- `src/sweet/http/response.mojo`: response formatter reused to produce raw HTTP bytes.
- `src/sweet/server/tcp.mojo`: moves from log-only callbacks to a minimal raw-bytes request handler that can send one response per read.
- `src/sweet/server/http.mojo`: stays intentionally small; parses bytes, constructs the simplest valid `HttpRequest`, routes only static paths, and returns `HttpResponse`.
- `tests/test_ffi_libuv.mojo`: libuv smoke tests.
- `tests/test_ffi_llhttp.mojo`: llhttp smoke tests.
- `tests/test_ffi_yyjson.mojo`: yyjson smoke tests.
- `examples/week2-tcp-server/main.mojo`: TCP smoke example.
- `examples/week2-http-server/main.mojo`: HTTP smoke example.

## Constraints To Preserve During Implementation

- Stay inside V1.0 from `.kiro/specs/axiom-api-framework/implementation-roadmap.md`.
- Do not add route params, wildcard routing, middleware, JSON request parsing, plugin hooks, DI, thread-per-core, or performance work.
- Do not widen `HttpRequest` beyond the smallest fields already present.
- Keep `types.mojo` and `src/sweet/__init__.mojo` untouched unless the compile path proves they are necessary.

### Task 1: Replace The Placeholder Error Module

**Files:**
- Modify: `src/sweet/core/error.mojo`

- [ ] **Step 1: Replace the placeholder comment with a minimal error surface**

```mojo
# Error types used by the current FFI and HTTP server slice.

alias ErrorKind = Int
alias ERROR_UNKNOWN = 0
alias ERROR_IO = 1
alias ERROR_PARSE = 2
alias ERROR_NETWORK = 3

struct Error:
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
```

- [ ] **Step 2: Re-read the FFI wrappers and confirm this file supports their current `raise Error("...")` usage**

Run: inspect `src/sweet/ffi/libuv.mojo`, `src/sweet/ffi/llhttp.mojo`, and `src/sweet/ffi/yyjson.mojo`
Expected: every existing `raise Error("...")` call matches the new single-argument initializer; no new error API is required yet

- [ ] **Step 3: Re-read `src/sweet/core/error.mojo` for accidental scope creep**

Run: inspect `src/sweet/core/error.mojo`
Expected: the file exposes only `ErrorKind`, four constant aliases, `Error`, and `describe()`

### Task 2: Replace The Placeholder Result Module And Export The Core Slice

**Files:**
- Modify: `src/sweet/core/result.mojo`
- Modify: `src/sweet/core/__init__.mojo`

- [ ] **Step 1: Replace the placeholder comment in `result.mojo` with the smallest `Result[T, E]` needed by `HttpServer`**

```mojo
from sweet.core.error import Error

struct Result[T, E]:
    var _is_ok: Bool
    var _value: Optional[T]
    var _error: Optional[E]

    def __init__(out self, is_ok: Bool, value: Optional[T], error: Optional[E]):
        self._is_ok = is_ok
        self._value = value
        self._error = error

    def is_ok(self) -> Bool:
        return self._is_ok

    def unwrap(self) raises -> T:
        if self._value is None:
            raise Error("Tried to unwrap an Err result")
        return self._value.value()

    def unwrap_err(self) raises -> E:
        if self._error is None:
            raise Error("Tried to unwrap_err an Ok result")
        return self._error.value()

def Ok[T, E](value: T) -> Result[T, E]:
    return Result[T, E](True, value, None)

def Err[T, E](error: E) -> Result[T, E]:
    return Result[T, E](False, None, error)
```

- [ ] **Step 2: Export the new core primitives from `src/sweet/core/__init__.mojo`**

```mojo
# Core types and utilities.

from .error import Error, ErrorKind, ERROR_UNKNOWN, ERROR_IO, ERROR_PARSE, ERROR_NETWORK
from .result import Result, Ok, Err
```

- [ ] **Step 3: Check the only current `Result` consumer against the new surface**

Run: inspect `src/sweet/server/http.mojo`
Expected: `Result`, `Ok`, `is_ok()`, `unwrap()`, and `unwrap_err()` are the only result APIs required by the current server path

- [ ] **Step 4: Keep `types.mojo` and `src/sweet/__init__.mojo` untouched unless the compile path proves otherwise**

Run: inspect imports in `src/` after the `Result` implementation lands
Expected: no code in the Week 2 slice imports `sweet.core.types` or the top-level `sweet` package directly

### Task 3: Extend The libuv Wrapper For One Read/One Response Flow

**Files:**
- Modify: `src/sweet/ffi/libuv.mojo`
- Test: `tests/test_ffi_libuv.mojo`

- [ ] **Step 1: Add the missing write-related aliases and a small buffer struct near the top of `libuv.mojo`**

```mojo
struct UVBuf:
    var base: UnsafePointer[UInt8]
    var len: Int

alias uv_buf_t = UnsafePointer[UVBuf]
alias uv_write_t = UnsafePointer[NoneType]

alias uv_alloc_cb = def(uv_handle_t, Int, uv_buf_t) -> None
alias uv_read_cb = def(uv_stream_t, Int, uv_buf_t) -> None
alias uv_connection_cb = def(uv_stream_t, Int) -> None
alias uv_write_cb = def(uv_write_t, Int) -> None
alias uv_close_cb = def(uv_handle_t) -> None
```

- [ ] **Step 2: Fix the low-level libuv write signature so it matches the narrow request-response flow this slice needs**

```mojo
def write(self, req: uv_write_t, stream: uv_stream_t, bufs: uv_buf_t, nbufs: Int, cb: uv_write_cb) -> Int:
    return external_call["uv_write", Int](req, stream, bufs, nbufs, cb)
```

- [ ] **Step 3: Add the smallest high-level `UVTcp` helpers needed by `TcpServer`**

```mojo
def accept_from(self, server: UVTcp) raises:
    let result = self.lib.accept(server.tcp, self.tcp)
    if result < 0:
        raise Error("Failed to accept TCP connection")

def read_start(self, alloc_cb: uv_alloc_cb, read_cb: uv_read_cb) raises:
    let result = self.lib.read_start(self.tcp, alloc_cb, read_cb)
    if result < 0:
        raise Error("Failed to start reading from TCP stream")

def read_stop(self) raises:
    let result = self.lib.read_stop(self.tcp)
    if result < 0:
        raise Error("Failed to stop reading from TCP stream")

def write_string(self, response: String, callback: uv_write_cb) raises:
    let req = UnsafePointer[NoneType].alloc(1)
    let buf = UnsafePointer[UVBuf].alloc(1)
    buf[].base = response.unsafe_ptr()
    buf[].len = len(response)
    let result = self.lib.write(req, self.tcp, buf, 1, callback)
    if result < 0:
        buf.free()
        req.free()
        raise Error("Failed to write to TCP stream")
```

- [ ] **Step 4: Leave the existing libuv smoke tests intact unless the revised aliases force a compile fix**

Run: inspect `tests/test_ffi_libuv.mojo`
Expected: keep the tests as construction smoke tests; only patch them if the wrapper surface change requires an import or signature adjustment

### Task 4: Upgrade `TcpServer` From Log-Only Callbacks To A Raw Request Handler

**Files:**
- Modify: `src/sweet/server/tcp.mojo`
- Modify: `examples/week2-tcp-server/main.mojo`

- [ ] **Step 1: Change the TCP handler contract to raw bytes in, response bytes out**

```mojo
from sweet.ffi.libuv import UVLoop, UVTcp, uv_buf_t, uv_stream_t, uv_handle_t, uv_write_t
from sweet.core.error import Error
from memory import UnsafePointer

alias ConnectionHandler = def(UnsafePointer[UInt8], Int) raises -> String
```

- [ ] **Step 2: Replace the optional handler storage with a default response handler in the constructor**

```mojo
struct TcpServer:
    var loop: UVLoop
    var tcp: UVTcp
    var host: String
    var port: Int
    var handler: ConnectionHandler

    def __init__(out self, host: String, port: Int) raises:
        self.host = host
        self.port = port
        self.loop = UVLoop()
        self.tcp = UVTcp(self.loop)

        def default_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
            return "Sweet TCP server received data\n"

        self.handler = default_handler
        self.tcp.bind(host, port)
```

- [ ] **Step 3: Replace the placeholder connection callback with accept/read/write callbacks**

```mojo
def listen(mut self, handler: ConnectionHandler, backlog: Int = 128) raises:
    self.handler = handler

    def alloc_callback(handle: uv_handle_t, suggested_size: Int, buf: uv_buf_t):
        buf[].base = UnsafePointer[UInt8].alloc(suggested_size)
        buf[].len = suggested_size

    def write_callback(req: uv_write_t, status: Int):
        if status < 0:
            print("Write error:", status)

    def read_callback(stream: uv_stream_t, nread: Int, buf: uv_buf_t):
        if nread <= 0:
            if buf != None:
                buf[].base.free()
                buf.free()
            return

        let response = self.handler(buf[].base, nread)
        var client = UVTcp(self.loop)
        client.tcp = stream
        client.write_string(response, write_callback)
        buf[].base.free()
        buf.free()

    def connection_callback(server: uv_stream_t, status: Int):
        if status < 0:
            print("Connection error:", status)
            return

        var client = UVTcp(self.loop)
        client.accept_from(self.tcp)
        client.read_start(alloc_callback, read_callback)

    self.tcp.listen(backlog, connection_callback)
```

- [ ] **Step 4: Keep the example intentionally simple and make its output match the new behavior**

```mojo
from sweet.server.tcp import create_echo_server

def main() raises:
    print("=== Week 2: TCP Server Example ===\n")
    print("Creating TCP server on 0.0.0.0:8000...")
    var server = create_echo_server("0.0.0.0", 8000)
    print("Starting server...")
    print("Test with: telnet localhost 8000")
    print("Press Ctrl+C to stop\n")
    server.run()
```

- [ ] **Step 5: Keep `create_echo_server()` as a smoke-test helper, not a real echo implementation**

```mojo
def create_echo_server(host: String, port: Int) raises -> TcpServer:
    var server = TcpServer(host, port)

    def echo_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
        return "Sweet TCP server received data\n"

    server.listen(echo_handler)
    return server
```

### Task 5: Wire `HttpServer` To Parse Bytes And Return A Static Route Response

**Files:**
- Modify: `src/sweet/server/http.mojo`
- Modify: `examples/week2-http-server/main.mojo`

- [ ] **Step 1: Update the imports so `HttpServer` can translate llhttp output into the existing request/response model**

```mojo
from sweet.server.tcp import TcpServer
from sweet.ffi.llhttp import HttpParser, HTTP_REQUEST, HTTP_GET, HTTP_POST
from sweet.http.request import HttpRequest
from sweet.http.response import HttpResponse
from sweet.core.result import Result, Ok
from sweet.core.error import Error
from memory import UnsafePointer
```

- [ ] **Step 2: Keep `handle_request()` narrow and explicit: parse bytes, map the method, build the simplest valid `HttpRequest`, and route only static paths**

```mojo
def handle_request(mut self, data: UnsafePointer[UInt8], length: Int) raises -> HttpResponse:
    _ = self.parser.parse(data, length)

    let method_code = self.parser.get_method()
    let version = self.parser.get_version()

    var method = "UNKNOWN"
    if method_code == HTTP_GET:
        method = "GET"
    elif method_code == HTTP_POST:
        method = "POST"

    # Keep the path explicit until llhttp path extraction is added in a later slice.
    var request = HttpRequest(method, "/")
    request.version = version

    if request.path in self.routes:
        let result = self.routes[request.path](request)
        if result.is_ok():
            return result.unwrap()

        let route_error = result.unwrap_err()
        return HttpResponse.error(500, route_error.describe())

    return HttpResponse.error(404, "Not Found")
```

- [ ] **Step 3: Replace the log-only connection handler in `run()` with a raw-bytes handler that uses `TcpServer`**

```mojo
def run(mut self) raises:
    print("🌐 HTTP Server starting...")

    def connection_handler(data: UnsafePointer[UInt8], length: Int) raises -> String:
        self.parser.reset()
        let response = self.handle_request(data, length)
        return response.to_bytes()

    self.tcp_server.listen(connection_handler)
    self.tcp_server.run()
```

- [ ] **Step 4: Keep the built-in example route static and minimal**

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

- [ ] **Step 5: Keep the example entrypoint as a smoke-test launcher only**

```mojo
from sweet.server.http import create_simple_server

def main() raises:
    print("=== Week 2: HTTP Server Example ===\n")
    print("Creating HTTP server on 0.0.0.0:8000...")
    var server = create_simple_server("0.0.0.0", 8000)
    print("Starting server...")
    print("Test with: curl http://localhost:8000/")
    print("Press Ctrl+C to stop\n")
    server.run()
```

### Task 6: Run The Week 2 Verification Path And Capture The Real Blocker

**Files:**
- Test: `tests/test_ffi_libuv.mojo`
- Test: `tests/test_ffi_llhttp.mojo`
- Test: `tests/test_ffi_yyjson.mojo`
- Test: `examples/week2-tcp-server/main.mojo`
- Test: `examples/week2-http-server/main.mojo`

- [ ] **Step 1: Verify the toolchain and shared-library prerequisites first**

Run: `mojo --version`
Expected: prints the installed Mojo version; if it fails with `mojo: command not found`, stop and record that environment blocker before blaming the code

Run: `pkg-config --modversion libuv`
Expected: prints a libuv version string

Run: `ls "vendor/llhttp/build"`
Expected: includes the built llhttp shared library or supporting build artifacts

- [ ] **Step 2: Run the three FFI smoke tests in the Week 2 order**

Run: `mojo run tests/test_ffi_libuv.mojo`
Expected: prints the libuv smoke-test banner and completes without raising an exception

Run: `mojo run tests/test_ffi_llhttp.mojo`
Expected: parses the sample GET request and prints the parsed method/version lines

Run: `mojo run tests/test_ffi_yyjson.mojo`
Expected: loads yyjson, parses the valid sample, and catches the invalid JSON case

- [ ] **Step 3: Run the TCP smoke example and confirm that a client receives a response**

Run in terminal 1: `mojo run examples/week2-tcp-server/main.mojo`
Expected: prints the TCP server startup banner and blocks in the event loop

Run in terminal 2: `telnet localhost 8000`
Expected: the server accepts one connection and returns `Sweet TCP server received data`

- [ ] **Step 4: Run the HTTP smoke example and confirm that `curl` receives a valid static response**

Run in terminal 1: `mojo run examples/week2-http-server/main.mojo`
Expected: prints the HTTP server startup banner and blocks in the event loop

Run in terminal 2: `curl -i http://localhost:8000/`
Expected: returns an `HTTP/1.1 200 OK` response with `Hello from Sweet!` in the body

- [ ] **Step 5: If verification is blocked by the environment, record the exact blocker instead of widening scope**

```text
Environment blocker example:
/bin/bash: line 1: mojo: command not found
```

Expected: the implementation notes clearly distinguish environment failures from code failures

## Self-Review

- Spec coverage: this plan covers the approved Week 2 slice in order: core primitives, narrow libuv stabilization, TCP request-response path, HTTP static route path, and the Week 2 verification sequence.
- Placeholder scan: no `TODO`, `TBD`, or “implement later” steps remain in the task list.
- Type consistency: the plan keeps one `Error` type, one `Result[T, E]` surface, one raw-bytes `ConnectionHandler`, and one `HttpResponse.to_bytes()` response path throughout.

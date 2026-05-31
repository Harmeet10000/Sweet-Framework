# Sweet Framework - Week 1-4 Detailed Tasks

## Week 1: Environment Setup & FFI Foundation

### Day 1-2: Environment Setup
- [x] Create installation script (`scripts/install-deps.sh`)
- [ ] Run installation script: `./scripts/install-deps.sh`
- [ ] Verify Mojo installation: `mojo --version`
- [ ] Verify C libraries installed:
  ```bash
  pkg-config --modversion libuv
  ls vendor/llhttp
  ls vendor/yyjson
  ```

### Day 3-4: FFI Wrappers
- [x] Create FFI directory structure
- [x] Write libuv FFI wrapper (`src/sweet/ffi/libuv.mojo`)
- [x] Write llhttp FFI wrapper (`src/sweet/ffi/llhttp.mojo`)
- [x] Write yyjson FFI wrapper (`src/sweet/ffi/yyjson.mojo`)
- [ ] Test each wrapper independently

### Day 5: FFI Testing
- [ ] Create test file: `tests/test_ffi_libuv.mojo`
- [ ] Test libuv event loop creation
- [ ] Test libuv TCP socket creation
- [ ] Create test file: `tests/test_ffi_llhttp.mojo`
- [ ] Test HTTP request parsing
- [ ] Create test file: `tests/test_ffi_yyjson.mojo`
- [ ] Test JSON parsing

### Day 6-7: RAII Safety Layer
- [ ] Add error handling to all FFI wrappers
- [ ] Test memory safety with valgrind
- [ ] Document FFI usage patterns
- [ ] Create examples in `examples/ffi/`

---

## Week 2: Minimal HTTP Server

### Day 1-2: TCP Server
- [ ] Create `src/sweet/server/tcp.mojo`
- [ ] Implement TCP server using libuv
- [ ] Accept connections
- [ ] Read data from sockets
- [ ] Write data to sockets
- [ ] Test with telnet

### Day 3-4: HTTP Request Handling
- [ ] Create `src/sweet/server/http.mojo`
- [ ] Integrate llhttp parser
- [ ] Parse HTTP requests
- [ ] Extract method, path, headers
- [ ] Test with curl

### Day 5: HTTP Response
- [ ] Create `src/sweet/http/response.mojo`
- [ ] Implement response builder
- [ ] Format HTTP response
- [ ] Send response to client
- [ ] Test full request-response cycle

### Day 6-7: Integration & Testing
- [ ] Create `examples/hello-world/main.mojo`
- [ ] Build minimal HTTP server
- [ ] Test with wrk: `wrk -t4 -c100 -d30s http://localhost:8000`
- [ ] Target: 10K RPS
- [ ] Fix bugs and optimize

---

## Week 3: Memory Management & Basic Routing

### Day 1-2: Arena Allocator
- [ ] Review existing `src/sweet/memory/arena.mojo`
- [ ] Implement per-request arena
- [ ] Add bounds checking
- [ ] Test allocation/deallocation
- [ ] Benchmark allocation overhead

### Day 3-4: Static Router
- [ ] Create `src/sweet/routing/static_router.mojo`
- [ ] Implement route registration
- [ ] Implement route matching (linear search)
- [ ] Test with multiple routes
- [ ] Benchmark routing performance

### Day 5: Request Context
- [ ] Create `src/sweet/http/context.mojo`
- [ ] Implement request context
- [ ] Attach arena to context
- [ ] Pass context to handlers
- [ ] Test context lifecycle

### Day 6-7: Integration
- [ ] Integrate arena with server
- [ ] Integrate router with server
- [ ] Create example with multiple routes
- [ ] Test memory usage
- [ ] Benchmark performance

---

## Week 4: Error Handling & JSON

### Day 1-2: Result Monad
- [ ] Review existing `src/sweet/core/result.mojo`
- [ ] Implement Result[T, E] type
- [ ] Implement Ok() and Err() constructors
- [ ] Implement map() and and_then()
- [ ] Test monad laws
- [ ] Create examples

### Day 3-4: Error Types
- [ ] Review existing `src/sweet/core/error.mojo`
- [ ] Define error types (ParseError, RouteError, etc.)
- [ ] Implement error-to-HTTP mapping
- [ ] Test error handling
- [ ] Create error examples

### Day 5: JSON Integration
- [ ] Create `src/sweet/json/parser.mojo`
- [ ] Wrap yyjson for parsing
- [ ] Create `src/sweet/json/serializer.mojo`
- [ ] Wrap yyjson for serialization
- [ ] Test JSON round-trip

### Day 6-7: Full Integration
- [ ] Update handlers to return Result
- [ ] Add JSON request/response support
- [ ] Create REST API example
- [ ] Test with curl
- [ ] Benchmark performance
- [ ] Target: 25-30K RPS

---

## Success Criteria for Week 1-4

### Functional Requirements
✅ Can accept TCP connections
✅ Can parse HTTP requests
✅ Can route to handlers
✅ Can send HTTP responses
✅ Can parse/serialize JSON
✅ Has error handling with Result monad
✅ Has per-request memory arena

### Performance Requirements
✅ 25-30K RPS on single core
✅ < 5ms p99 latency
✅ < 2KB memory per request
✅ No memory leaks (valgrind clean)

### Code Quality
✅ All FFI wrappers tested
✅ Example applications work
✅ Documentation complete
✅ No compiler warnings

---

## Testing Checklist

### Unit Tests
- [ ] FFI wrappers (libuv, llhttp, yyjson)
- [ ] Arena allocator
- [ ] Router
- [ ] Result monad
- [ ] Error types
- [ ] JSON parser/serializer

### Integration Tests
- [ ] TCP server accepts connections
- [ ] HTTP request parsing
- [ ] Route matching
- [ ] Handler execution
- [ ] Response sending
- [ ] JSON request/response

### Load Tests
- [ ] wrk benchmark (30 seconds)
- [ ] Sustained load (1 hour)
- [ ] Connection exhaustion test
- [ ] Memory leak test (valgrind)

### Manual Tests
- [ ] curl GET request
- [ ] curl POST request with JSON
- [ ] Multiple concurrent connections
- [ ] Invalid HTTP requests
- [ ] Large request bodies

---

## Troubleshooting Guide

### FFI Issues
**Problem**: Can't load shared library
**Solution**: Check LD_LIBRARY_PATH, verify library exists

**Problem**: Segfault in FFI call
**Solution**: Check pointer validity, verify function signature

**Problem**: Memory leak
**Solution**: Ensure all RAII wrappers call destructors

### Performance Issues
**Problem**: Low RPS
**Solution**: Profile with perf, check for blocking calls

**Problem**: High latency
**Solution**: Check for unnecessary allocations, optimize hot paths

**Problem**: Memory usage growing
**Solution**: Check arena reset, run valgrind

### Build Issues
**Problem**: Mojo compiler errors
**Solution**: Check Mojo version, update syntax

**Problem**: Linker errors
**Solution**: Verify library paths, check symbols

---

## Next Steps After Week 4

Once Week 1-4 is complete, proceed to:
- **Week 5-6**: Middleware system
- **Week 7-8**: Validation system
- **Week 9-10**: HTTP client
- **Week 11-12**: Thread-per-core architecture

See `implementation-roadmap.md` for full V1 plan.

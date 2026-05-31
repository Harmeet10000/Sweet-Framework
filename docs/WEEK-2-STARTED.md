# Week 2 - TCP & HTTP Server Implementation STARTED 🚀

## What We've Built

### 1. FFI Layer ✅
- `src/sweet/ffi/libuv.mojo` - libuv event loop bindings
- `src/sweet/ffi/llhttp.mojo` - HTTP parser bindings
- `src/sweet/ffi/yyjson.mojo` - JSON parser bindings

### 2. Server Infrastructure ✅
- `src/sweet/server/tcp.mojo` - TCP server with libuv
- `src/sweet/server/http.mojo` - HTTP server built on TCP

### 3. HTTP Types ✅
- `src/sweet/http/request.mojo` - HttpRequest struct
- `src/sweet/http/response.mojo` - HttpResponse struct with formatting

### 4. Examples ✅
- `examples/week2-tcp-server/main.mojo` - TCP echo server
- `examples/week2-http-server/main.mojo` - HTTP hello world server

## Current Status

### What Works (In Theory)
- ✅ TCP server structure
- ✅ HTTP server structure
- ✅ Request/Response types
- ✅ Basic routing concept

### What Needs Work
- ⚠️ **FFI callbacks** - Need to properly handle C callbacks in Mojo
- ⚠️ **Connection handling** - Need to implement actual read/write
- ⚠️ **HTTP parsing integration** - Need to wire llhttp to request handling
- ⚠️ **Memory management** - Need to ensure proper cleanup

## Next Steps (This Week)

### Day 1-2: Fix FFI and Test
1. **Test FFI wrappers individually**
   ```bash
   # Set library path
   export LD_LIBRARY_PATH=$PWD/vendor/llhttp/build:$PWD/vendor/c-ares/build/lib:$LD_LIBRARY_PATH
   
   # Test each wrapper
   mojo run tests/test_ffi_libuv.mojo
   mojo run tests/test_ffi_llhttp.mojo
   mojo run tests/test_ffi_yyjson.mojo
   ```

2. **Fix any issues**
   - Adjust function signatures
   - Fix pointer types
   - Handle Mojo syntax errors

### Day 3-4: Implement Connection Handling
1. **TCP connection acceptance**
   - Implement proper callback handling
   - Accept incoming connections
   - Read data from sockets

2. **Data reading**
   - Allocate read buffers
   - Handle partial reads
   - Pass data to HTTP parser

### Day 5: HTTP Request Parsing
1. **Integrate llhttp**
   - Parse incoming HTTP data
   - Extract method, path, headers
   - Build HttpRequest object

2. **Route matching**
   - Simple path matching
   - Call registered handlers

### Day 6-7: Response Sending & Testing
1. **Send HTTP responses**
   - Format response with headers
   - Write to socket
   - Close connection

2. **End-to-end testing**
   ```bash
   # Run server
   mojo run examples/week2-http-server/main.mojo
   
   # Test with curl
   curl http://localhost:8000/
   
   # Benchmark
   wrk -t4 -c100 -d10s http://localhost:8000/
   ```

## Known Issues & Challenges

### 1. Mojo FFI Callbacks
**Problem**: C libraries use callbacks, Mojo FFI callback support is unclear

**Solutions**:
- Option A: Use function pointers if Mojo supports them
- Option B: Create C wrapper that handles callbacks
- Option C: Use polling instead of callbacks (less efficient)

### 2. Memory Management
**Problem**: Need to manage C library memory from Mojo

**Solutions**:
- Use RAII wrappers (already started)
- Ensure all allocations are freed
- Test with valgrind

### 3. Async I/O Integration
**Problem**: libuv is async, Mojo doesn't have native async yet

**Solutions**:
- Use libuv's event loop (blocking)
- Handle callbacks synchronously
- Wait for Mojo Phase 2 async for better integration

## Testing Strategy

### Unit Tests
- [ ] Test TCP server creation
- [ ] Test HTTP request parsing
- [ ] Test HTTP response formatting
- [ ] Test route registration

### Integration Tests
- [ ] Test full request-response cycle
- [ ] Test multiple concurrent connections
- [ ] Test error handling

### Manual Tests
```bash
# Test TCP server
telnet localhost 8000

# Test HTTP server
curl -v http://localhost:8000/
curl -X POST http://localhost:8000/ -d '{"test": "data"}'

# Load test
wrk -t4 -c100 -d30s http://localhost:8000/
```

## Performance Targets

### Week 2 Goals
- **Throughput**: 10,000 RPS (single core)
- **Latency**: p99 < 10ms
- **Stability**: Run for 1 hour without crashes
- **Memory**: No leaks (valgrind clean)

### If We Hit Issues
- Focus on correctness first
- Performance can be optimized later
- Document any blockers

## Code Structure

```
src/sweet/
├── ffi/                    # FFI wrappers (DONE)
│   ├── libuv.mojo
│   ├── llhttp.mojo
│   └── yyjson.mojo
├── server/                 # Server implementations (IN PROGRESS)
│   ├── tcp.mojo           # TCP server
│   └── http.mojo          # HTTP server
├── http/                   # HTTP types (DONE)
│   ├── request.mojo
│   └── response.mojo
└── core/                   # Core types (TODO)
    ├── result.mojo        # Result monad
    └── error.mojo         # Error types
```

## Resources

### Documentation
- [libuv docs](https://docs.libuv.org/en/v1.x/)
- [llhttp docs](https://github.com/nodejs/llhttp)
- [Mojo FFI docs](https://docs.modular.com/mojo/manual/ffi)

### Similar Projects
- Node.js (uses libuv + llhttp)
- Bun (uses uWebSockets)
- Deno (uses Rust + Tokio)

## Questions to Answer

1. **How do we handle C callbacks in Mojo?**
   - Need to test and document

2. **Can we pass Mojo functions to C?**
   - Need to verify FFI capabilities

3. **How do we manage memory across FFI boundary?**
   - Need clear ownership rules

4. **What's the performance overhead of FFI?**
   - Need to benchmark

## Success Criteria

By end of Week 2, we should have:
- ✅ Working TCP server that accepts connections
- ✅ Working HTTP server that parses requests
- ✅ Ability to send HTTP responses
- ✅ At least one working example
- ✅ Basic tests passing
- ✅ No memory leaks

## Let's Build! 🔨

The foundation is laid. Now we need to:
1. Test the FFI wrappers
2. Fix any issues
3. Implement connection handling
4. Wire everything together
5. Test and benchmark

**Current Priority**: Test FFI wrappers and fix any issues before proceeding.

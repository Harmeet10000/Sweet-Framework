# Sweet - High-Performance API Framework for Mojo

Sweet is a high-performance API server framework written in Mojo that combines the developer experience of FastAPI, the architectural principles of Fastify, and the AOT compilation approach of ElysiaJS.

But I should warn you this is for my fun and being nerdy. Learning while doing and breaking things is better than just chatting with AI,although I will be using AI extensively for writing code but if someone has a better understanding of the subject then please lets work together.

## Key Features

- **Sub-millisecond Latency**: Achieves p99 latency under 1ms through MLIR-based AOT compilation and SIMD acceleration
- **Million+ RPS Throughput**: 60K-100K requests per second per core with linear scaling across cores
- **Thread-Per-Core Architecture**: Shared-nothing design eliminates cross-core synchronization and cache coherency issues
- **Zero-Copy HTTP Parsing**: SIMD-accelerated parsing with StringRef for zero-allocation request handling
- **Railway Oriented Programming**: Explicit error handling with Result monad for type-safe error propagation
- **Real-Time Communication**: Native WebSocket and Server-Sent Events (SSE) with lock-free broadcasting
- **Background Tasks**: Broker-backed task queue with SPSC buffers and Redis integration
- **Cron Scheduling**: AOT cron compilation with min-heap execution
- **Compile-Time Optimization**: Routes, validation, and serialization compiled at build time

## Architecture

```
Client Request
    ↓
Kernel SO_REUSEPORT (load distribution)
    ↓
Worker Core (thread-per-core, isolated)
    ├─ io_uring Reactor (async I/O)
    ├─ HTTP Parser (SIMD, zero-copy)
    ├─ AOT Router (radix trie)
    ├─ Middleware Chain (ROP)
    ├─ Handler Function
    ├─ JSON Serializer (SIMD)
    ├─ Memory Arena (O(1) deallocation)
    ├─ Background Task Queue (SPSC/Redis)
    ├─ Cron Scheduler (min-heap)
    ├─ WebSocket Manager (lock-free broadcasting)
    └─ SSE Manager (timing wheel keep-alives)
```

## Quick Start

```mojo
from sweet import Application, ServerConfig, HttpMethod, HttpResponse

fn main() raises:
    var config = ServerConfig(
        host="0.0.0.0",
        port=8000,
        num_workers=4
    )
    
    var app = Application(config)
    
    # Register routes
    app.route("/", HttpMethod.GET, hello_handler)
    app.route("/users/:id", HttpMethod.GET, get_user_handler)
    
    # Start server
    app.run()

fn hello_handler(request: HttpRequest, params: RouteParams) raises -> Result[HttpResponse, Error]:
    var response = HttpResponse(200)
    response.body = "Hello, Sweet!"
    return Ok(response)
```

## Core Components

### 1. Network Reactor
- io_uring (Linux 5.1+) or epoll for async I/O
- SO_REUSEPORT for kernel-level load balancing
- TCP_NODELAY and TCP_QUICKACK for latency optimization

### 2. HTTP Parser
- Zero-copy SIMD-accelerated HTTP/1.1 parsing
- StringRef for buffer references without allocations
- SIMD delimiter detection (CRLF, colons)

### 3. AOT Router
- Compile-time route compilation into radix trie
- O(path_length) route matching
- Path parameter extraction

### 4. Validation System
- Compile-time schema validation
- Pydantic-like DX with zero runtime cost
- Field-level error reporting

### 5. JSON Serializer
- SIMD-accelerated JSON parsing and serialization
- Zero-copy where possible
- Proper escape sequence handling

### 6. Middleware System
- Railway Oriented Programming (ROP) error handling
- Lifecycle hooks: on_request, pre_handler, on_response, on_error
- Request/response transformation

### 7. WebSocket Manager
- RFC 6455 compliant handshake
- Zero-copy SIMD frame unmasking (AVX-512)
- Lock-free broadcasting with SPSC ring buffers
- Topic-based subscriptions
- Rate limiting and frame size validation
- Redis Pub/Sub for cross-instance broadcasting

### 8. Server-Sent Events (SSE)
- Long-lived HTTP connections with chunked encoding
- Zero-copy event formatting
- Hashed timing wheel for efficient keep-alives
- Topic-based broadcasting
- Last-Event-ID support for reconnection

### 9. Background Tasks
- Non-blocking task enqueueing
- SPSC buffers (single-core) or Redis broker (multi-core)
- Retry logic with exponential backoff
- Dead letter queue for permanent failures

### 10. Cron Scheduler
- AOT cron expression compilation
- Min-heap for efficient next-job lookup
- Job persistence to pluggable storage

### 11. Dependency Injection
- Functional and decorator-based DI
- Singleton and factory lifecycles
- Compile-time resolution where possible

### 12. Structured Logging
- Zero-allocation logging with memory arena
- Structured key-value fields
- Multiple log sinks (stdout, file, network)

## Performance Targets

- **Latency**: p99 < 1ms for typical API operations
- **Throughput**: 60K-100K RPS per core, 1M+ RPS on 16 cores
- **Memory**: < 1KB per request (excluding application data)
- **Scalability**: Linear scaling with core count (no contention)

## System Requirements

- **OS**: Linux (primary), macOS (development), Windows (future)
- **Kernel**: Linux 5.1+ (io_uring), 3.9+ (SO_REUSEPORT)
- **CPU**: x86_64 with AVX2 support
- **RAM**: 4GB minimum, 16GB+ recommended
- **Mojo**: 0.26.3+

## Optional Dependencies

- **Redis**: For distributed background tasks and rate limiting
- **PostgreSQL/MySQL**: Application-level data storage
- **Monitoring**: Prometheus, Jaeger, Grafana

## Documentation

- [Design Document](.kiro/specs/sweet-api-framework/design.md) - Comprehensive architecture and algorithms

## License

[To be determined]

## Contributing

[Contributing guidelines to be added]

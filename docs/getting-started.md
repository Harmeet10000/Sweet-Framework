# Getting Started with Sweet Framework

## Prerequisites

- **Mojo**: Version 24.5 or later
- **OS**: Linux (primary), macOS (development)
- **CPU**: x86_64 with AVX2 (for V2 SIMD features)
- **RAM**: 4GB minimum

## Installation

### Step 1: Install Dependencies

Run the installation script to install all C library dependencies:

```bash
./scripts/install-deps.sh
```

This will install:
- libuv (event loop)
- liburing (io_uring, Linux only)
- llhttp (HTTP parser)
- yyjson (JSON parser)
- c-ares (async DNS)

### Step 2: Verify Installation

Check that everything is installed correctly:

```bash
# Verify Mojo
mojo --version

# Verify C libraries
pkg-config --modversion libuv
ls vendor/llhttp
ls vendor/yyjson
ls vendor/c-ares
```

### Step 3: Run Tests

Test the FFI wrappers:

```bash
# Test libuv FFI
mojo run tests/test_ffi_libuv.mojo

# Test llhttp FFI
mojo run tests/test_ffi_llhttp.mojo

# Test yyjson FFI
mojo run tests/test_ffi_yyjson.mojo
```

## Quick Start

### Hello World Example

Create `my_app.mojo`:

```mojo
from sweet import Application, ServerConfig

fn hello_handler(request: HttpRequest, params: RouteParams) raises -> Result[HttpResponse, Error]:
    var response = HttpResponse(200)
    response.body = "Hello, Sweet!"
    return Ok(response)

fn main() raises:
    var config = ServerConfig(
        host="0.0.0.0",
        port=8000,
        num_workers=1
    )
    
    var app = Application(config)
    app.route("/", HttpMethod.GET, hello_handler)
    app.run()
```

Run it:

```bash
mojo run my_app.mojo
```

Test it:

```bash
curl http://localhost:8000/
# Output: Hello, Sweet!
```

## Development Workflow

### 1. Write Code

Edit files in `src/sweet/`

### 2. Run Tests

```bash
mojo test
```

### 3. Benchmark

```bash
# Install wrk
sudo apt install wrk

# Run benchmark
wrk -t4 -c100 -d30s http://localhost:8000
```

### 4. Profile

```bash
# Memory profiling
valgrind --leak-check=full mojo run my_app.mojo

# CPU profiling
perf record mojo run my_app.mojo
perf report
```

## Project Structure

```
sweet/
├── src/sweet/           # Framework source code
│   ├── ffi/            # FFI wrappers for C libraries
│   ├── http/           # HTTP request/response
│   ├── routing/        # Router implementation
│   ├── memory/         # Arena allocator
│   ├── core/           # Result monad, error types
│   └── ...
├── tests/              # Test files
├── examples/           # Example applications
├── docs/               # Documentation
├── scripts/            # Utility scripts
└── vendor/             # Third-party C libraries
```

## Next Steps

- Read [Week 1-4 Tasks](week-1-4-tasks.md) for detailed development plan
- Read [Implementation Roadmap](../.kiro/specs/axiom-api-framework/implementation-roadmap.md) for full V1-V3 plan
- Check [TODO](todo.md) for current priorities

## Troubleshooting

### Can't load shared library

**Problem**: `Failed to load libuv library`

**Solution**:
```bash
# Add to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Or install to system location
sudo ldconfig
```

### Mojo compiler errors

**Problem**: Syntax errors or type errors

**Solution**:
- Check Mojo version: `mojo --version`
- Update to latest: Follow Mojo installation guide
- Check syntax against Mojo documentation

### Low performance

**Problem**: < 10K RPS in benchmarks

**Solution**:
- Profile with perf: `perf record -g mojo run my_app.mojo`
- Check for blocking calls
- Verify FFI overhead is minimal
- Ensure release build (not debug)

## Getting Help

- **Documentation**: See `docs/` directory
- **Examples**: See `examples/` directory
- **Issues**: Check existing issues or create new one
- **Discussions**: Join community discussions

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

See [LICENSE](../LICENSE) for details.

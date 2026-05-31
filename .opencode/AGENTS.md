# Sweet Project

## Role

Use the repository docs as the source of truth for how this framework is meant to evolve. Favor the current Mojo-first architecture over generic backend advice.

## Stack Snapshot

- Mojo 0.26.3+
- libuv, liburing, llhttp, yyjson, c-ares
- Thread-per-core server model
- io_uring or epoll reactor
- HTTP parsing, routing, middleware, validation, serialization
- Background tasks, cron, SSE, WebSocket, structured logging

## First Reads

- `README.md`
- `README-PROGRESS.md`
- `NEXT-STEPS.md`
- `STATUS.md`
- `INSTALLATION-COMPLETE.md`
- `.kiro/specs/axiom-api-framework/requirements.md`
- `.kiro/specs/axiom-api-framework/design.md`
- `.kiro/specs/axiom-api-framework/implementation-roadmap.md`

## Working Rules

- Keep handlers, transport, and core logic separated.
- Prefer explicit data flow and small functions.
- Reuse existing modules under `src/sweet/` before inventing new abstractions.
- Keep performance and memory ownership in view when editing server, parser, or serialization code.
- If `graphify-out/graph.json` appears later, use `graphify query`, `graphify path`, or `graphify explain` before raw grep.

## Audit Findings

- The codebase still uses the deprecated Mojo `fn` keyword in many places.
- Current Mojo docs prefer `def` for all function declarations and methods.
- Constructors and method receivers should be reviewed against current Mojo ownership syntax before expanding the API surface.
- The project is still scaffold-level in several modules, so correctness and compatibility matter more than feature growth right now.

## Example Paths

- `examples/week2-http-server/main.mojo`
- `examples/week2-tcp-server/main.mojo`
- `examples/rest-api/main.mojo`
- `examples/hello-world/main.mojo`

## Useful Commands

```bash
./scripts/install-deps.sh
mojo --version
mojo run tests/test_ffi_libuv.mojo
mojo run tests/test_ffi_llhttp.mojo
mojo run tests/test_ffi_yyjson.mojo
valgrind mojo run tests/test_ffi_libuv.mojo
wrk -t4 -c100 -d30s http://localhost:8000/
```

## Quality Focus

- Keep the framework aligned with the current docs and roadmaps.
- Verify changes with the smallest relevant Mojo command set.
- Prefer correctness first, then performance, then broadening scope.

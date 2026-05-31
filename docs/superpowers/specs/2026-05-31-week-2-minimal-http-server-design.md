# Week 2 Minimal HTTP Server Design

## Summary

This spec defines the next safe implementation slice for Sweet's Week 2 work: unblock compilation for the already-migrated FFI and server path, then carry the server to a minimal static HTTP loop that is narrow enough to verify with telnet, curl, and the existing FFI tests once Mojo is available.

The goal is not to build the full framework from the Kiro spec. The goal is to complete the V1.0 proof-of-concept slice described in `docs/WEEK-1-COMPLETE.md` and `.kiro/specs/axiom-api-framework/implementation-roadmap.md`: prove the FFI layer is usable, accept a TCP connection, parse an HTTP request, and send a valid static HTTP response.

## Goals

- Make the current Week 2 server path compile by implementing the missing core primitives already imported by the code.
- Keep the FFI wrappers and tests aligned with the current Mojo syntax migration already applied in the previous slice.
- Extend the TCP and HTTP server path from placeholder logging to a minimal accept -> read -> parse -> respond flow.
- Preserve a narrow, testable scope that matches the V1.0 roadmap rather than jumping ahead to V1.1 features.

## Non-Goals

- No repo-wide framework implementation.
- No route parameters, wildcard routing, middleware chain, validation system, JSON response generation, plugin system, DI, or thread-per-core work.
- No attempt to fully implement the long-form Kiro architecture in this slice.
- No performance optimization work beyond keeping the implementation simple enough to benchmark later.

## Source Of Truth

- `docs/WEEK-1-COMPLETE.md`
- `.kiro/specs/axiom-api-framework/implementation-roadmap.md`
- `.kiro/specs/axiom-api-framework/requirements.md`
- `.kiro/specs/axiom-api-framework/design.md`

For this slice, the roadmap is the strongest scope constraint. The requirements and design documents describe the eventual system, but this implementation should stop at the V1.0 proof-of-concept boundary.

## Scoped Files

Primary implementation files:

- `src/sweet/core/error.mojo`
- `src/sweet/core/result.mojo`
- `src/sweet/core/types.mojo` only if required to satisfy the compile path
- `src/sweet/__init__.mojo` only if required to expose the minimal public API
- `src/sweet/server/tcp.mojo`
- `src/sweet/server/http.mojo`

Verification targets:

- `tests/test_ffi_libuv.mojo`
- `tests/test_ffi_llhttp.mojo`
- `tests/test_ffi_yyjson.mojo`
- `examples/week2-tcp-server/main.mojo`
- `examples/week2-http-server/main.mojo`

Already-migrated FFI wrappers should only receive narrow follow-up edits if the new compile path or verification flow requires them.

## Design Approach

### 1. Compilation Unblock First

The current HTTP server already imports `Result`, `Ok`, and `Error`, but the corresponding modules are empty placeholders. The first step is to make those imports real with the smallest surface area needed by the existing code.

`core/error.mojo` should provide:

- a lightweight `ErrorKind`
- a lightweight `Error`
- enough constructors and fields for FFI wrappers and the HTTP server to raise and inspect errors consistently

`core/result.mojo` should provide:

- `Result[T, E]`
- `Ok(value)`
- `Err(error)`
- `is_ok()`
- `unwrap()`
- `unwrap_err()`

Nothing more should be added unless a direct caller in the current slice needs it.

### 2. Minimal TCP Server Behavior

`server/tcp.mojo` currently binds and listens, but the connection callback only logs a message. This slice should move it to the first useful behavior needed for the Week 2 checklist:

- accept a connection through the existing libuv wrapper path
- read request bytes into a buffer or a minimal handoff structure
- write a response back to the client
- keep callback handling explicit and simple enough to debug

If the current libuv wrapper is not yet sufficient for full read/write flow, the implementation may stop at the narrowest working behavior that can still support HTTP request-response smoke testing. The design should prefer a direct, debuggable flow over a generalized callback abstraction.

### 3. Minimal HTTP Server Behavior

`server/http.mojo` should remain intentionally narrow:

- parse the incoming request bytes with `HttpParser`
- construct the simplest valid `HttpRequest` object the current code can support
- match only static routes stored in the existing route table
- return a static `HttpResponse`

This slice should keep the request model placeholder-safe where llhttp integration is still incomplete, but it must remove obviously fake behavior where possible. For example, hard-wiring the request path to `"/"` is acceptable only until enough parser data can be extracted to route a basic request correctly.

### 4. Verification Order

The execution order should match the Week 2 checklist:

1. FFI tests
2. TCP smoke test
3. HTTP smoke test with telnet or curl
4. Follow-up bug fixes required to make the narrow path stable

Because `mojo` is currently unavailable in the environment, verification is expected to remain partially blocked until the toolchain is installed or exposed on `PATH`. The design still assumes those commands are the success gate once the environment is ready.

## Phases

### Phase 1: Core Primitive Implementation

- Implement `ErrorKind` and `Error`
- Implement `Result[T, E]`, `Ok`, and `Err`
- Add only the minimum compile-path helpers required by the current FFI and HTTP server code

### Phase 2: FFI Stabilization Pass

- Re-check the FFI tests against the new core primitives
- Patch any narrow type/signature issues surfaced by the compile path
- Document any FFI patterns that prove to be accepted by the current Mojo toolchain

### Phase 3: TCP Connection Path

- Advance the TCP server from bind/listen/log to accept/read/write behavior
- Keep the connection path explicit, not abstract
- Ensure the server can support a single connection-response loop for smoke testing

### Phase 4: HTTP Request/Response Path

- Feed the raw bytes into llhttp
- Build the simplest valid `HttpRequest`
- Route a static path
- Return a valid HTTP response body and headers

### Phase 5: Verification

- Run the three FFI tests
- Run the Week 2 TCP example
- Run the Week 2 HTTP example
- Smoke-test with telnet and curl if the environment allows it

## Risks

### Risk 1: Mojo Toolchain Unavailable

The environment currently does not expose `mojo`, so runtime verification is blocked until that is fixed.

Mitigation:

- keep the slice narrow and reviewable
- preserve verification commands in the implementation plan
- treat environment availability as an external blocker, not a reason to widen the code scope

### Risk 2: FFI Callback Complexity

The libuv callback path may require more context plumbing than the current wrapper exposes.

Mitigation:

- prefer the narrowest direct callback flow that can support one working request-response cycle
- avoid introducing reusable abstractions until the behavior works end-to-end

### Risk 3: Premature Scope Expansion

The Kiro spec describes a much larger framework than the Week 2 checklist requires.

Mitigation:

- keep every change tied to the V1.0 roadmap deliverables
- reject features that belong to V1.1 or later unless they are unavoidable compile blockers

## Acceptance Criteria

This slice is complete when:

- `src/sweet/core/error.mojo` and `src/sweet/core/result.mojo` are no longer placeholders and satisfy the current compile path
- the FFI test files are still aligned with the migrated Mojo syntax and current core modules
- the TCP server path is advanced beyond placeholder logging toward a real request-response loop
- the HTTP server can parse a basic request and produce a static response for a registered static route
- the resulting code remains intentionally minimal and does not jump ahead into V1.1 features

## Follow-Up After This Slice

Once the minimal HTTP proof-of-concept works, the next logical work should come from the V1.1 roadmap:

- stronger request construction from parsed data
- better static route matching behavior
- first real error mapping
- JSON request/response support

Those should be planned as a separate slice after the current Week 2 path is stable.

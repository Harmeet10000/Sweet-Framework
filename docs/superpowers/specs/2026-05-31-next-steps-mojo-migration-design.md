# Next Steps Mojo Migration Design

## Summary

This design covers the first safe migration slice for Sweet based on `NEXT-STEPS.md`.
The goal is to modernize the core Week 2 execution path to current Mojo syntax and make the first validation targets runnable without attempting a risky repo-wide rewrite.

The migration is intentionally limited to the FFI wrappers, the minimal TCP/HTTP server path, the request/response types, and the tests/examples that exercise them.

## Goals

- Align the first runnable slice of Sweet with current Mojo syntax guidance.
- Implement the first actionable items from `NEXT-STEPS.md`.
- Establish a working base for FFI validation before expanding feature work.
- Keep the migration narrow enough that failures are attributable and reversible.

## Non-Goals

- No repo-wide syntax sweep across every module under `src/sweet/`.
- No attempt to finish all planned framework features.
- No performance optimization beyond preserving the current intended structure.
- No speculative refactor of unfinished subsystems unrelated to the Week 2 path.

## Source of Truth

- `NEXT-STEPS.md`
- `README.md`
- `README-PROGRESS.md`
- Current Mojo docs for functions and structs

## Migration Scope

The migration is restricted to the files directly involved in the first runnable path.

### Core library files

- `src/sweet/ffi/libuv.mojo`
- `src/sweet/ffi/llhttp.mojo`
- `src/sweet/ffi/yyjson.mojo`
- `src/sweet/server/tcp.mojo`
- `src/sweet/server/http.mojo`
- `src/sweet/http/request.mojo`
- `src/sweet/http/response.mojo`

### Verification targets

- `tests/test_ffi_libuv.mojo`
- `tests/test_ffi_llhttp.mojo`
- `tests/test_ffi_yyjson.mojo`
- `examples/week2-http-server/main.mojo`
- `examples/week2-tcp-server/main.mojo`

## Design Approach

### 1. Syntax-first migration

The first change set updates deprecated Mojo constructs in the scoped files.

Expected syntax updates include:

- `fn` to `def`
- `inout self` constructors to current constructor forms
- mutable instance methods to `mut self` where field mutation is required
- any adjacent ownership spelling that prevents the scoped files from compiling

This phase is not a style pass. Only syntax and ownership changes needed to keep the current code intent intact should be made.

### 2. Make `NEXT-STEPS.md` runnable in order

The root file prioritizes:

1. FFI wrapper validation
2. syntax fixes
3. connection handling
4. example execution

Implementation will follow that order.

The first success target is getting the three FFI test files onto a modern syntax footing with the smallest required library-wrapper fixes.

### 3. Minimal implementation over broad expansion

Where `NEXT-STEPS.md` points to incomplete behavior, the implementation should add the smallest correct behavior needed for the scoped examples/tests.

Examples:

- preserve placeholder-safe HTTP routing instead of inventing a full router
- implement only the first connection/listen path needed to exercise the TCP layer
- avoid widening APIs unless the existing examples/tests require it

## Planned Phases

### Phase 1: Current Mojo syntax migration

- Update the scoped source files from deprecated function syntax.
- Update the scoped tests and examples to match the same syntax.
- Keep names and public file boundaries stable where possible.

### Phase 2: FFI validation fixes

- Fix obvious wrapper issues that block simple construction or parse tests.
- Keep wrapper behavior simple and explicit.
- Prefer direct wrapper correctness over abstraction.

### Phase 3: Minimal TCP/HTTP path completion

- Implement the first missing connection-handling steps called out in `NEXT-STEPS.md`.
- Keep HTTP handling intentionally narrow and placeholder-safe.
- Avoid claiming full request parsing or response I/O unless actually wired.

### Phase 4: Verification

Run the smallest relevant commands first:

- `mojo run tests/test_ffi_libuv.mojo`
- `mojo run tests/test_ffi_llhttp.mojo`
- `mojo run tests/test_ffi_yyjson.mojo`

If those pass, run:

- `mojo run examples/week2-tcp-server/main.mojo`
- `mojo run examples/week2-http-server/main.mojo`

## Error Handling

- Preserve explicit failure behavior in FFI wrappers.
- Prefer clear early errors when a shared library or parser operation fails.
- Do not hide missing implementation behind fake success paths.

## Testing Strategy

- Use the three existing FFI tests as the first acceptance gate.
- Treat example entrypoints as smoke tests, not proof of complete server behavior.
- If verification is blocked by environment or library-loading issues, report the exact blocker and stop widening changes.

## Risks

- The repo appears to mix deprecated syntax with partially scaffolded runtime code.
- FFI signatures may have issues separate from the syntax migration.
- A broad migration could spill into unfinished modules and create noisy failures.

## Risk Controls

- Restrict edits to the scoped files listed above.
- Verify in the same order as `NEXT-STEPS.md`.
- Do not migrate unrelated modules during this pass.

## Acceptance Criteria

- The scoped files no longer rely on deprecated `fn` syntax.
- The scoped tests/examples are updated consistently with the migrated library code.
- At least the FFI validation path is runnable or reduced to a clearly reported non-syntax blocker.
- The Week 2 path is in a better state than before without a repo-wide rewrite.

## Follow-Up After This Design

If this slice succeeds, the next planning pass can extend the same migration strategy to adjacent modules such as routing, middleware, validation, and public API exports.

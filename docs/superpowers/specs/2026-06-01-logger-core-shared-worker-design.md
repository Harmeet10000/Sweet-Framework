# Logger Core Shared Worker Design

**Goal:** Replace duplicated per-logger queue/worker/sink state with a shared logger core so child loggers truly share the parent worker, while preserving the existing real file sink path.

**Scope:** This slice only covers the logger subsystem. It does not add OS threads, network transport, or arena-backed zero-allocation logging.

## Problem

The current `Logger` implementation duplicates runtime state on `child()`. Each child logger constructs its own `LogQueue`, `LogWorker`, and sink list, then re-adds copied sinks into the new worker. This violates the enhancement spec's expectation that child loggers share the parent worker, and it makes counters, flush behavior, and sink ownership diverge across parent and child instances.

The file sink is now real enough to write to disk, but the worker and logger ownership model is still value-oriented and fragmented. That means the next useful step is not more feature breadth, but making logger runtime state coherent.

## Design Summary

Introduce a shared `LoggerCore` runtime object that owns the mutable logging pipeline:

- `LogQueue`
- `LogWorker`
- registered sinks
- shared counters derived from the worker/queue

Each `Logger` instance will own only per-view configuration and context:

- level threshold
- inherited structured fields
- serializer chain
- sampler configuration
- logical clock for timestamp generation
- a reference to the shared `LoggerCore`

Parent and child loggers will then differ only in contextual fields and local filtering rules, while enqueueing into the same shared processing path.

## Architecture

### `LoggerCore`

`LoggerCore` is the single source of truth for runtime logging state. It owns the queue and worker together because they are semantically one processing pipeline.

Responsibilities:

- initialize queue and worker from `LogConfig`
- register sinks exactly once for the shared pipeline
- accept serialized payloads for enqueueing
- expose `flush()` for draining queued work and flushing sinks
- expose shared processed/dropped counters

It must not know about log levels, contextual fields, serializers, or sampling policy. Those remain logger concerns.

### `Logger`

`Logger` becomes a lightweight contextual view over `LoggerCore`.

Responsibilities:

- apply level filtering
- apply sampling decisions
- merge inherited and per-call fields
- serialize fields into JSON payloads
- pass payloads into the shared core
- create child loggers that reuse the same core

`Logger.child()` must copy contextual fields and configuration values, but it must not allocate a new queue, worker, or sink set.

### `LogWorker`

`LogWorker` remains synchronous for this slice, but its API should align with shared ownership:

- own queue and sinks for the shared runtime
- support repeated enqueue/drain/flush calls from multiple `Logger` views
- expose `processed_count`

This slice keeps `LogWorker` in-process and single-threaded. The goal is correctness of shared ownership, not background execution.

## Data Flow

### Parent logger flow

1. `Logger.log()` checks level threshold.
2. `Logger.log()` checks sampler policy.
3. `Logger.log()` builds `LogEntry` with merged fields.
4. `Logger.log()` serializes fields and produces JSON payload.
5. `Logger.log()` calls shared core enqueue.
6. Shared core writes into the shared queue/worker path.

### Child logger flow

1. `Logger.child()` creates a new logger view with copied contextual fields.
2. The child receives the same `LoggerCore` as the parent.
3. Child `log()` calls enqueue into the same shared queue and worker.
4. Parent and child therefore contribute to the same sink outputs, processed count, queue state, and flush behavior.

## File and Module Changes

### New file

- `src/sweet/logging/core.mojo`
  - defines `LoggerCore`
  - encapsulates queue/worker/sink runtime state

### Modified files

- `src/sweet/logging/logger.mojo`
  - remove direct ownership of `sinks`, `queue`, and `worker`
  - add shared core ownership
  - update `child()`, `add_sink()`, `log()`, `flush()`, and dropped-message reporting

- `src/sweet/logging/worker.mojo`
  - keep the current synchronous drain model
  - ensure it works as the shared runtime engine behind `LoggerCore`

- `src/sweet/logging/__init__.mojo`
  - export `LoggerCore` if needed by tests or downstream code

- `tests/unit/test_http_client_logger_enhancement.mojo`
  - verify child logger shares processing path with parent

- `tests/property/test_logger_properties.mojo`
  - verify shared-worker semantics remain correct under sampling

- `tests/integration/test_http_client_logger_enhancement.mojo`
  - verify real file sink still writes to disk through shared logger core

## Ownership Model

The key design constraint is avoiding value-copy divergence.

The implementation should prefer one of these two concrete strategies:

1. Use a dedicated shared runtime wrapper that is explicitly passed and reused by value-safe APIs.
2. Use the smallest Mojo-supported indirection/reference pattern already compatible with the repo.

The implementation must choose the smallest pattern that allows these invariants:

- adding a sink on the parent affects the child because the sink registration lives in shared core state
- `processed_count` observed after child logging reflects shared work
- `flush()` on either parent or child drains the same queue
- dropped message counts come from shared runtime state rather than per-logger duplicates

## Error Handling

This slice keeps existing error behavior simple.

- If a sink is unavailable, the sink increments its own `error_count` and the worker continues to other sinks.
- If enqueue fails because the queue is full, the shared dropped count increases through queue/core state.
- `flush()` remains best-effort and should not panic on sink write failure.

No new public error types are added in this slice.

## Testing Plan

### Unit

- parent logger adds sink, child logger writes, parent-observable processed count increases
- child logger inherits fields without mutating parent fields
- dropped message reporting reflects shared queue state rather than per-instance duplication

### Property-style

- sampled-out messages remain excluded
- error-level messages still bypass sampling
- child and parent logging preserve a single shared processing count

### Integration

- rotating file sink still writes actual JSON log lines to a real file
- child logger writes through the same shared runtime and reaches disk
- `flush()` after child logging leaves file contents complete and queue drained

## Non-Goals

These remain out of scope for this slice:

- OS-threaded background worker
- lock-free queue implementation
- real network sink transport
- arena allocator integration
- HTTP client transport/runtime work

## Acceptance Criteria For This Slice

This design is complete when:

- `Logger.child()` no longer creates an independent queue/worker pipeline
- parent and child share one logging runtime path
- real file sink behavior still works through that shared path
- current unit, property, integration, and benchmark logger-adjacent checks keep passing

## Self-Review

- No placeholders remain.
- Scope is limited to logger shared-runtime correctness.
- The design does not promise OS threads or network transport in this pass.
- The design matches the current repo state and only extends the logger subsystem where the spec gap is already known.

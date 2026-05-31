# Logger UDP Network Sink Design

**Goal:** Turn the current metadata-only network log sink into a real UDP localhost transport path that works through the shared logger core and is covered by focused integration verification.

**Scope:** This slice only covers logger network sink transport for UDP localhost delivery. It does not add TCP support, batching, retry logic, background threads, or remote-service protocols.

## Problem

The logger now has a shared runtime core and a real file sink, but `create_network_sink()` still only creates metadata. Writes to a network sink do not send anything over the network, so the logger does not yet satisfy the spec's network sink direction in any meaningful way.

The smallest correct next step is to add one real network path that is easy to verify end-to-end. UDP localhost delivery is the best fit because it avoids connection lifecycle complexity while still proving that the logging pipeline can leave the process and reach an external receiver.

## Design Summary

Keep the existing `LogSink` type and extend its `write()` behavior so that `sink_type == "network"` can send datagrams when the destination is a UDP endpoint.

Supported endpoint format in this slice:

- `udp://127.0.0.1:1514`
- `udp://localhost:1514`

When `LogSink.write()` receives a network sink with a supported UDP destination:

1. Parse host and port from the endpoint string.
2. Send the log line as a UDP datagram.
3. Preserve the current in-memory `entries` append for observability.
4. Increment `error_count` and return if sending fails.

The logger pipeline itself does not change shape. Parent and child loggers continue to share `LoggerCore`; the network sink becomes another real sink reachable through that shared runtime.

## Architecture

### `LogSink`

`LogSink` remains the central sink runtime type. This slice extends its responsibility only slightly:

- keep file sink behavior unchanged
- keep memory sink behavior unchanged
- add UDP send behavior for a constrained `network` case

The network behavior should remain deliberately narrow. The sink should not attempt to become a generic transport framework.

### `create_network_sink()`

`create_network_sink(endpoint)` continues to return a `LogSink` with `sink_type == "network"` and the provided destination string. The factory stays thin.

### Local UDP Receiver For Tests

Integration verification needs a real receiver that can prove the payload arrived. The simplest acceptable test harness for this slice is a localhost UDP receiver process or helper that:

- binds to a test port
- receives one datagram
- writes the received payload to a known file or exposes it to the test

The important point is that the assertion must be based on received network data, not on sink-local `entries` alone.

## Data Flow

1. `Logger.log()` builds and serializes JSON payload.
2. `LoggerCore` enqueues and flushes through the shared runtime.
3. `LogWorker` calls `LogSink.write(payload)`.
4. `LogSink.write()` recognizes `sink_type == "network"`.
5. The sink parses the UDP endpoint and sends a datagram.
6. The local test receiver receives the payload and records it for verification.

## File and Module Changes

### Modified files

- `src/sweet/logging/sink.mojo`
  - add UDP endpoint parsing and send behavior for `network` sinks

- `src/sweet/logging/sinks/network.mojo`
  - keep the factory thin, but document/use UDP endpoint format consistently

- `tests/integration/test_http_client_logger_enhancement.mojo`
  - either extend or complement with a logger-network integration path that verifies UDP receipt

### Optional support files

- a small local helper script or test fixture may be added if Mojo-only UDP receiving is too heavy for this slice
- any helper must stay narrowly scoped to integration verification

## Endpoint Format

Supported in this slice:

- `udp://127.0.0.1:<port>`
- `udp://localhost:<port>`

Rejected or unsupported in this slice:

- `tcp://...`
- hostnames other than `localhost` unless they already parse cleanly and require no extra resolution logic
- query parameters, auth fragments, or structured protocol options

If the endpoint is malformed, the sink increments `error_count` and returns without crashing the logger pipeline.

## Error Handling

- malformed UDP endpoint: increment `error_count`, do not send
- socket creation/send failure: increment `error_count`, do not panic
- if multiple sinks are registered, failure in the network sink must not block other sinks

This slice does not add retries, backoff, reconnection, or queueing inside the sink.

## Testing Plan

### Integration

- create a logger with a UDP network sink
- emit a log line through the shared logger core
- verify a local UDP receiver captured the payload
- verify file sink behavior remains unaffected if both sinks are registered together

### Regression

- existing file-sink integration continues to pass
- advanced example using `create_network_sink()` continues to run without breaking shared-core logger behavior

## Non-Goals

These remain out of scope for this slice:

- TCP network sink support
- TLS or authenticated transports
- background send threads
- batching, retries, or buffering inside the network sink
- remote log protocols like syslog framing, GELF, or OTLP

## Acceptance Criteria For This Slice

This design is complete when:

- `create_network_sink("udp://127.0.0.1:<port>")` results in real UDP delivery
- the payload travels through the shared logger core, not a side path
- integration verification proves receipt with a local UDP receiver
- sink failures increment `error_count` without breaking the rest of the logger pipeline

## Self-Review

- No placeholders remain.
- Scope is narrow and limited to UDP localhost delivery.
- The design does not promise TCP, retry logic, or background transport behavior.
- The design builds directly on the current shared logger core and real file sink work.

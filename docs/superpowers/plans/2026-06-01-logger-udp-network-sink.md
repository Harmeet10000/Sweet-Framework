# Logger UDP Network Sink Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real UDP localhost network log sink that sends payloads through the shared logger core and is verified by a focused integration test.

**Architecture:** Extend the existing `LogSink` runtime so `sink_type == "network"` can parse `udp://host:port` destinations and send datagrams over a real socket. Keep the existing shared `LoggerCore` path unchanged so network delivery happens through the same worker and sink pipeline as file delivery.

**Tech Stack:** Mojo, Sweet logging modules, existing shared `LoggerCore`, `std.pathlib.Path`, small local UDP test helper if needed, `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo`

---

## File Structure

- Modify: `src/sweet/logging/sink.mojo`
  - Add UDP endpoint parsing and real send behavior.
- Modify: `src/sweet/logging/sinks/network.mojo`
  - Keep the network sink factory aligned with the supported UDP endpoint format.
- Create or Modify: `tests/integration/test_http_client_logger_enhancement.mojo`
  - Add integration coverage that proves a UDP receiver gets the payload.
- Create: `tests/integration/udp_log_receiver.py` or similar narrow helper if Mojo-only receive path is too heavy
  - Receive one UDP datagram on localhost and persist it for the test to inspect.

### Task 1: Expose The Failing UDP Integration Path

**Files:**
- Modify: `tests/integration/test_http_client_logger_enhancement.mojo`
- Create: `tests/integration/udp_log_receiver.py`

- [ ] **Step 1: Write the failing integration test**

Add a UDP integration path to the existing logger integration test:

```mojo
from sweet.logging import Logger, LogConfig, InfoLevel, create_network_sink
from std.pathlib import Path

def main() raises:
    var received_path = Path("/tmp/sweet-udp.log")
    received_path.write_text("")

    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(create_network_sink("udp://127.0.0.1:15140"))
    logger.info("udp-log")
    logger.flush()

    assert_true("udp-log" in received_path.read_text(), "UDP receiver should capture logger payload")
```

Create a narrow localhost helper receiver:

```python
import socket
from pathlib import Path

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 15140))
data, _ = sock.recvfrom(65535)
Path("/tmp/sweet-udp.log").write_text(data.decode("utf-8"))
sock.close()
```

- [ ] **Step 2: Run test to verify it fails**

Run the receiver in a separate shell/process, then run:

`pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`

Expected: FAIL because the current network sink does not send anything.

- [ ] **Step 3: Keep the helper minimal and deterministic**

If the Python helper is needed, keep it as a single-use fixture script with no retries, no threads, and a single datagram receive path.

- [ ] **Step 4: Re-run the test to confirm the failure is specifically network-delivery related**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: FAIL on the UDP payload assertion, not on logger construction or file sink paths.

- [ ] **Step 5: Commit**

```bash
git add tests/integration/test_http_client_logger_enhancement.mojo tests/integration/udp_log_receiver.py
git commit -m "test: add failing udp logger integration"
```

### Task 2: Add UDP Endpoint Parsing To LogSink

**Files:**
- Modify: `src/sweet/logging/sink.mojo:1-80`
- Modify: `src/sweet/logging/sinks/network.mojo:1-10`
- Test: `tests/integration/test_http_client_logger_enhancement.mojo`

- [ ] **Step 1: Add a narrow parser test expectation in the integration flow**

Strengthen the integration case to prove malformed endpoints do not crash the logger pipeline:

```mojo
var bad_sink = create_network_sink("udp://bad-endpoint")
bad_sink.write("payload")
assert_true(bad_sink.error_count >= 1, "malformed UDP endpoint should increment error_count")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: FAIL because network sink still has no real parsing/send path.

- [ ] **Step 3: Write minimal UDP endpoint parsing support**

Add small helpers in `src/sweet/logging/sink.mojo`:

```mojo
def parse_udp_destination(destination: String) -> Optional[(String, Int)]:
    if not destination.startswith("udp://"):
        return None
    var remainder = String(destination.split("udp://")[1])
    if ":" not in remainder:
        return None
    var host_port = remainder.rsplit(":", 1)
    if len(host_port) != 2:
        return None
    return (String(host_port[0]), Int(String(host_port[1])))
```

Keep the factory thin:

```mojo
def create_network_sink(endpoint: String) -> LogSink:
    return LogSink("network:" + endpoint, "network", endpoint)
```

- [ ] **Step 4: Run test to verify parsing-related assertions now pass or fail only on send behavior**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: malformed endpoint assertion passes; UDP payload delivery still fails until send logic is added.

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/sink.mojo src/sweet/logging/sinks/network.mojo tests/integration/test_http_client_logger_enhancement.mojo
git commit -m "feat: parse udp logger sink destinations"
```

### Task 3: Implement Real UDP Send Behavior

**Files:**
- Modify: `src/sweet/logging/sink.mojo:1-120`
- Test: `tests/integration/test_http_client_logger_enhancement.mojo`
- Test: `tests/integration/udp_log_receiver.py`

- [ ] **Step 1: Keep the failing integration assertion in place**

The integration test should still assert receipt via `/tmp/sweet-udp.log`:

```mojo
assert_true("udp-log" in received_path.read_text(), "UDP receiver should capture logger payload")
```

- [ ] **Step 2: Run test to verify it still fails before send logic**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: FAIL on missing UDP payload.

- [ ] **Step 3: Write minimal UDP send implementation**

Implement real send behavior in `LogSink.write()` using the narrow UDP-only path. If Mojo socket APIs are insufficiently ergonomic in-repo, call the smallest existing POSIX-compatible path available to send one datagram.

Target behavior:

```mojo
    if self.sink_type == "network" and len(self.destination) > 0:
        var parsed = parse_udp_destination(self.destination)
        if parsed is None:
            self.error_count += 1
            return
        try:
            send_udp_payload(parsed.value()[0], parsed.value()[1], entry)
        except:
            self.error_count += 1
            return
```

Where `send_udp_payload()` is a tiny helper dedicated to one datagram send.

- [ ] **Step 4: Run integration test to verify it passes**

Run the receiver helper, then run:

`pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`

Expected: PASS and `/tmp/sweet-udp.log` contains the JSON payload.

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/sink.mojo tests/integration/test_http_client_logger_enhancement.mojo tests/integration/udp_log_receiver.py
git commit -m "feat: send logger payloads over udp"
```

### Task 4: Verify Shared-Core Compatibility And Regression Safety

**Files:**
- Modify: `tests/integration/test_http_client_logger_enhancement.mojo`
- Test: `examples/http-client-and-logger-advanced/main.mojo`
- Test: `tests/property/test_logger_properties.mojo`
- Test: `tests/unit/test_http_client_logger_enhancement.mojo`

- [ ] **Step 1: Extend integration to prove shared-core compatibility**

Use a child logger with the UDP sink so delivery travels through the shared runtime:

```mojo
var logger = Logger(InfoLevel(), LogConfig())
logger.add_sink(create_network_sink("udp://127.0.0.1:15140"))
var child = logger.child("request_id", "udp")
child.info("udp-log")
logger.flush()
assert_true("request_id" in received_path.read_text(), "child logger metadata should travel through shared udp sink")
```

- [ ] **Step 2: Run focused regression tests**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/property/test_logger_properties.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: PASS

- [ ] **Step 3: Run example compatibility check**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo examples/http-client-and-logger-advanced/main.mojo`
Expected: PASS

- [ ] **Step 4: Inspect receiver output**

Read:

```text
/tmp/sweet-udp.log
```

Expected: JSON log line includes `udp-log` and shared child metadata such as `request_id`.

- [ ] **Step 5: Commit**

```bash
git add tests/integration/test_http_client_logger_enhancement.mojo
git commit -m "test: verify shared udp logger sink delivery"
```

### Task 5: Final Verification Sweep

**Files:**
- Modify: `src/sweet/logging/sink.mojo`
- Modify: `src/sweet/logging/sinks/network.mojo`
- Modify: `tests/integration/test_http_client_logger_enhancement.mojo`
- Create: `tests/integration/udp_log_receiver.py`

- [ ] **Step 1: Run the complete logger verification set**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/property/test_logger_properties.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: PASS

- [ ] **Step 2: Run example and benchmark compatibility checks**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo examples/http-client-and-logger-advanced/main.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo benchmarks/http_client_logger_enhancement.mojo`
Expected: PASS

- [ ] **Step 3: Inspect real outputs**

Read:

```text
/tmp/sweet.log
/tmp/sweet-advanced.log
/tmp/sweet-udp.log
```

Expected:
- file sink outputs still contain JSON log lines
- UDP receiver output contains the logger payload received over the network

- [ ] **Step 4: Review scope discipline**

Confirm the change set remains limited to:

```text
src/sweet/logging/sink.mojo
src/sweet/logging/sinks/network.mojo
tests/integration/test_http_client_logger_enhancement.mojo
tests/integration/udp_log_receiver.py
```

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/sink.mojo src/sweet/logging/sinks/network.mojo tests/integration/test_http_client_logger_enhancement.mojo tests/integration/udp_log_receiver.py
git commit -m "feat: add udp network logger sink"
```

## Self-Review

- Spec coverage: the plan covers real UDP delivery, endpoint parsing, shared-core compatibility, and integration verification with a localhost receiver.
- Placeholder scan: no `TODO`, `TBD`, or vague “write tests later” steps remain.
- Type consistency: `create_network_sink`, `parse_udp_destination`, `send_udp_payload`, and shared logger-core behavior are named consistently throughout the plan.

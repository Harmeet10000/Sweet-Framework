# Logger Core Shared Worker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make parent and child loggers share one runtime logging pipeline while preserving the real file sink path and keeping the logger subsystem internally consistent.

**Architecture:** Introduce a `LoggerCore` runtime object that owns the queue, worker, and sinks, then refactor `Logger` into a lightweight contextual view over that shared core. Keep the current synchronous drain model, but make `child()` reuse the same pipeline so counters, flush behavior, and file output are shared.

**Tech Stack:** Mojo, Sweet logging modules, `std.pathlib.Path`, existing Mojo test drivers run through `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo`

---

## File Structure

- Create: `src/sweet/logging/core.mojo`
  - Shared runtime owner for `LogQueue`, `LogWorker`, and sink registration.
- Modify: `src/sweet/logging/logger.mojo`
  - Remove duplicated runtime ownership from `Logger`; route logging through `LoggerCore`.
- Modify: `src/sweet/logging/worker.mojo`
  - Keep the synchronous worker model, but shape it for shared-core ownership.
- Modify: `src/sweet/logging/__init__.mojo`
  - Export the new shared core if needed by tests/importers.
- Modify: `tests/unit/test_http_client_logger_enhancement.mojo`
  - Assert parent/child shared processing behavior.
- Modify: `tests/property/test_logger_properties.mojo`
  - Assert shared processing still behaves correctly with sampling.
- Modify: `tests/integration/test_http_client_logger_enhancement.mojo`
  - Assert child logging reaches the real file sink through the shared pipeline.

### Task 1: Add Shared Logger Core

**Files:**
- Create: `src/sweet/logging/core.mojo`
- Modify: `src/sweet/logging/worker.mojo:1-42`
- Test: `tests/unit/test_http_client_logger_enhancement.mojo`

- [ ] **Step 1: Write the failing unit test**

Add a focused test that proves a child logger must share the parent runtime path:

```mojo
def test_logger_child_shares_runtime() raises:
    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(LogSink("memory"))

    var child = logger.child("request_id", "abc123")
    child.info("child-message")
    child.flush()

    assert_true(logger.worker.processed_count == 1, "parent should observe child processing through shared runtime")
    assert_true(child.worker.processed_count == 1, "child should observe same processed count")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: FAIL because parent and child currently use different workers.

- [ ] **Step 3: Write minimal shared-core implementation**

Create `src/sweet/logging/core.mojo` with a focused runtime owner:

```mojo
from sweet.logging.queue import LogQueue
from sweet.logging.sink import LogSink
from sweet.logging.worker import LogWorker
from sweet.logging.config import LogConfig

struct LoggerCore(Movable):
    var worker: LogWorker

    def __init__(out self, config: LogConfig = LogConfig()):
        var queue = LogQueue(config.queue_size, config.drop_on_full)
        self.worker = LogWorker(queue)
        self.worker.start()

    def add_sink(mut self, sink: LogSink):
        self.worker.add_sink(sink)

    def enqueue(mut self, payload: String) -> Bool:
        return self.worker.enqueue(payload)

    def flush(mut self):
        self.worker.flush()

    def processed_count(self) -> Int:
        return self.worker.processed_count

    def dropped_count(self) -> Int:
        return self.worker.queue.dropped_count
```

Keep `LogWorker` focused and value-safe:

```mojo
struct LogWorker(Movable):
    var queue: LogQueue
    var sinks: List[LogSink]
    var processed_count: Int
    var running: Bool
```

- [ ] **Step 4: Run test to verify it still fails in a narrower way or compile-check the new file**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: FAIL or compile error now shifts into `Logger`, because `child()` still constructs an independent runtime.

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/core.mojo src/sweet/logging/worker.mojo tests/unit/test_http_client_logger_enhancement.mojo
git commit -m "feat: add shared logger core foundation"
```

### Task 2: Refactor Logger To Use Shared Core

**Files:**
- Modify: `src/sweet/logging/logger.mojo:66-162`
- Modify: `src/sweet/logging/__init__.mojo:1-10`
- Test: `tests/unit/test_http_client_logger_enhancement.mojo`

- [ ] **Step 1: Update the failing unit test with a stronger shared-state assertion**

Expand the test to check shared dropped/processed behavior through both parent and child:

```mojo
def test_logger_child_shares_runtime() raises:
    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(LogSink("memory"))

    var child = logger.child("request_id", "abc123")
    child.info("child-message")
    logger.flush()

    assert_true(logger.worker.processed_count == 1, "parent should observe child processing")
    assert_true(child.worker.processed_count == 1, "child should observe shared processing")
    assert_true(logger.dropped_messages() == child.dropped_messages(), "dropped counts should come from shared runtime")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: FAIL because `Logger` still owns independent `queue`, `worker`, and `sinks` state.

- [ ] **Step 3: Write minimal `Logger` refactor**

Replace duplicated runtime ownership with shared core ownership:

```mojo
from sweet.logging.core import LoggerCore

struct Logger(Movable):
    var config: LogConfig
    var level: LogLevel
    var fields: Dict[String, String]
    var core: LoggerCore
    var serializer: LogSerializer
    var sampler_enabled: Bool
    var sampler: LogSampler
    var dropped_count: Int
    var clock_ms: Int

    @property
    def worker(mut self) -> ref [mut=True] LogWorker:
        return self.core.worker

    def __init__(out self, level: LogLevel = InfoLevel(), config: LogConfig = LogConfig()):
        self.config = config.copy()
        self.level = level.copy()
        self.fields = Dict[String, String]()
        self.core = LoggerCore(config)
        self.serializer = LogSerializer()
        self.serializer.register_builtin_sensitive_serializers()
        self.sampler_enabled = config.enable_sampling
        self.sampler = LogSampler(config.sampling_rate_percent, config.deterministic_sampling)
        self.dropped_count = 0
        self.clock_ms = 0

    def add_sink(mut self, sink: LogSink):
        self.core.add_sink(sink)

    def child(self, key: String, value: String) -> Logger:
        var logger = Logger(self.level.copy(), self.config.copy())
        logger.core = self.core
        for item in self.fields.items():
            logger.fields[item.key] = item.value
        logger.fields[key] = value
        logger.serializer = self.serializer.copy()
        logger.sampler_enabled = self.sampler_enabled
        logger.sampler = self.sampler.copy()
        return logger^

    def flush(mut self):
        self.core.flush()

    def dropped_messages(self) -> Int:
        return self.dropped_count + self.core.dropped_count()
```

Export the shared core:

```mojo
from .core import *
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/core.mojo src/sweet/logging/logger.mojo src/sweet/logging/__init__.mojo tests/unit/test_http_client_logger_enhancement.mojo
git commit -m "feat: share logger runtime across children"
```

### Task 3: Preserve Sampling And Shared Flush Behavior

**Files:**
- Modify: `tests/property/test_logger_properties.mojo:1-19`
- Modify: `src/sweet/logging/logger.mojo:121-162`
- Test: `tests/property/test_logger_properties.mojo`

- [ ] **Step 1: Write the failing property-style test**

Extend the property-style test so it exercises sampling plus shared runtime behavior:

```mojo
def main() raises:
    var logger = Logger(InfoLevel(), LogConfig(enable_sampling=True, sampling_rate_percent=50))
    logger.add_sink(LogSink("memory"))
    logger.with_sampler(LogSampler(0, True))

    var child = logger.child("request_id", "req-1")
    child.info("skip-me")
    child.error("keep-me")
    logger.flush()

    assert_true(logger.worker.processed_count == 1, "error log should bypass sampling through shared worker")
    assert_true(child.worker.processed_count == 1, "child should observe same processed count")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/property/test_logger_properties.mojo`
Expected: FAIL if shared runtime wiring or flush behavior is incomplete.

- [ ] **Step 3: Write minimal implementation adjustments**

Make `log()` enqueue through the core and keep flush centralized:

```mojo
    def log(mut self, level: LogLevel, message: String, fields: Dict[String, String] = Dict[String, String]()):
        if level.value < self.level.value:
            return
        if self.sampler_enabled and not self.sampler.should_sample(level, message):
            return
        self.tick(1)
        var entry = LogEntry(level.copy(), message, self.clock_ms)
        for item in self.fields.items():
            entry.fields[item.key] = item.value
        for item in fields.items():
            entry.fields[item.key] = item.value
        entry.fields = self.serializer.apply(entry.fields)
        if self.sampler_enabled:
            entry.fields["sample_rate"] = String(self.sampler.rate_percent)
            entry.fields["sampled"] = "true"
        var payload = entry.to_json()
        if not self.core.enqueue(payload):
            self.dropped_count += 1
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/property/test_logger_properties.mojo`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/logger.mojo tests/property/test_logger_properties.mojo
git commit -m "test: verify shared logger sampling behavior"
```

### Task 4: Verify Real File Sink Through Shared Core

**Files:**
- Modify: `tests/integration/test_http_client_logger_enhancement.mojo:1-26`
- Test: `tests/integration/test_http_client_logger_enhancement.mojo`
- Test: `examples/http-client-and-logger-advanced/main.mojo`

- [ ] **Step 1: Write the failing integration assertion**

Update the integration test so the child logger writes through the shared runtime to the real file sink:

```mojo
def main() raises:
    var log_path = Path("/tmp/sweet.log")
    log_path.write_text("")

    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(create_rotating_file_sink("/tmp/sweet.log", 4096))
    var child = logger.child("request_id", "integration")
    child.info("integration-log")
    logger.flush()

    assert_true(logger.worker.processed_count >= 1, "shared worker should process child message")
    assert_true("integration-log" in log_path.read_text(), "child logger should write to disk through shared file sink")
```

- [ ] **Step 2: Run test to verify it fails if the shared sink path is incomplete**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: FAIL only if sink registration or shared flush behavior is still wrong.

- [ ] **Step 3: Write minimal implementation fixes if needed**

Keep sink ownership in the shared core/worker path and avoid per-logger duplicate flushing. The intended steady state is:

```mojo
    def add_sink(mut self, sink: LogSink):
        self.core.add_sink(sink)

    def flush(mut self):
        self.core.flush()
```

- [ ] **Step 4: Run integration and example verification**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo examples/http-client-and-logger-advanced/main.mojo`
Expected: PASS and `/tmp/sweet-advanced.log` contains the advanced example JSON log line.

- [ ] **Step 5: Commit**

```bash
git add tests/integration/test_http_client_logger_enhancement.mojo
git commit -m "test: verify shared logger core with real file sink"
```

### Task 5: Final Verification Sweep

**Files:**
- Modify: `src/sweet/logging/core.mojo`
- Modify: `src/sweet/logging/logger.mojo`
- Modify: `src/sweet/logging/worker.mojo`
- Test: `tests/unit/test_http_client_logger_enhancement.mojo`
- Test: `tests/property/test_logger_properties.mojo`
- Test: `tests/integration/test_http_client_logger_enhancement.mojo`
- Test: `benchmarks/http_client_logger_enhancement.mojo`

- [ ] **Step 1: Run focused logger verification**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/unit/test_http_client_logger_enhancement.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/property/test_logger_properties.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo tests/integration/test_http_client_logger_enhancement.mojo`
Expected: PASS

- [ ] **Step 2: Run broader compatibility checks**

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo examples/http-client-and-logger-advanced/main.mojo`
Expected: PASS

Run: `pixi run mojo run -I src -I .pixi/envs/default/lib/mojo benchmarks/http_client_logger_enhancement.mojo`
Expected: PASS

- [ ] **Step 3: Inspect real file output**

Run: `ls "/tmp"`
Expected: output includes `sweet.log` and `sweet-advanced.log`

Then read:

```text
/tmp/sweet.log
/tmp/sweet-advanced.log
```

Expected: each file contains JSON log lines written by the shared logger pipeline.

- [ ] **Step 4: Review changed files for scope discipline**

Confirm only the logger subsystem and its direct tests changed:

```text
src/sweet/logging/core.mojo
src/sweet/logging/logger.mojo
src/sweet/logging/worker.mojo
src/sweet/logging/__init__.mojo
tests/unit/test_http_client_logger_enhancement.mojo
tests/property/test_logger_properties.mojo
tests/integration/test_http_client_logger_enhancement.mojo
```

- [ ] **Step 5: Commit**

```bash
git add src/sweet/logging/core.mojo src/sweet/logging/logger.mojo src/sweet/logging/worker.mojo src/sweet/logging/__init__.mojo tests/unit/test_http_client_logger_enhancement.mojo tests/property/test_logger_properties.mojo tests/integration/test_http_client_logger_enhancement.mojo
git commit -m "feat: share logger worker runtime"
```

## Self-Review

- Spec coverage: the plan covers shared worker/core ownership, child logger reuse of runtime state, shared flush behavior, and preservation of the real file sink path.
- Placeholder scan: no `TODO`, `TBD`, or undefined “write tests for above” steps remain.
- Type consistency: `LoggerCore`, `LogWorker`, `Logger.child()`, `add_sink()`, `flush()`, and `dropped_messages()` are named consistently throughout the tasks.

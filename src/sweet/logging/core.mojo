# Shared runtime owner for logger pipeline state.

from std.memory import UnsafePointer, alloc

from sweet.logging.config import LogConfig
from sweet.logging.queue import LogQueue
from sweet.logging.sink import LogSink
from sweet.logging.worker import LogWorker


struct LoggerCoreState(Movable):
    var worker: LogWorker
    var ref_count: Int

    def __init__(out self, config: LogConfig = LogConfig()):
        var queue = LogQueue(config.queue_size, config.drop_on_full)
        self.worker = LogWorker(queue)
        self.worker.start()
        self.ref_count = 1


struct LoggerCore(Copyable):
    var state: UnsafePointer[LoggerCoreState, MutExternalOrigin]

    def __init__(out self, config: LogConfig = LogConfig()):
        self.state = alloc[LoggerCoreState](1)
        self.state.init_pointee_move(LoggerCoreState(config))

    def __init__(out self, *, copy: Self):
        self.state = copy.state
        self.state[].ref_count += 1

    def __del__(deinit self):
        self.state[].ref_count -= 1
        if self.state[].ref_count == 0:
            self.state.destroy_pointee()
            self.state.free()

    def add_sink(mut self, sink: LogSink):
        self.state[].worker.add_sink(sink)

    def enqueue(mut self, payload: String) -> Bool:
        return self.state[].worker.enqueue(payload)

    def flush(mut self):
        self.state[].worker.flush()

    def processed_count(self) -> Int:
        return self.state[].worker.processed_count

    def dropped_count(self) -> Int:
        return self.state[].worker.queue.dropped_count

    def sink_count(self) -> Int:
        return len(self.state[].worker.sinks)

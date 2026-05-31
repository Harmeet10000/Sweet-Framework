# Background-style log worker foundation.

from sweet.logging.queue import LogQueue
from sweet.logging.sink import LogSink


struct LogWorker(Movable):
    var queue: LogQueue
    var sinks: List[LogSink]
    var processed_count: Int
    var running: Bool

    def __init__(out self, queue: LogQueue = LogQueue()):
        self.queue = queue.copy()
        self.sinks = List[LogSink]()
        self.processed_count = 0
        self.running = False

    def add_sink(mut self, sink: LogSink):
        self.sinks.append(sink.copy())

    def start(mut self):
        self.running = True

    def stop(mut self):
        self.running = False

    def enqueue(mut self, payload: String) -> Bool:
        return self.queue.enqueue(payload)

    def drain_once(mut self) -> Bool:
        var payload = self.queue.dequeue()
        if payload is None:
            return False
        for i in range(len(self.sinks)):
            self.sinks[i].write(payload.value())
        self.processed_count += 1
        return True

    def flush(mut self):
        while self.drain_once():
            pass

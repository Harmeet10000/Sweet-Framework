# Structured logger foundations.

from sweet.logging.config import LogConfig
from sweet.logging.core import LoggerCore
from sweet.logging.sampler import LogSampler
from sweet.logging.serializer import LogSerializer, FieldSerializer
from sweet.logging.sink import LogSink


struct LogLevel(Copyable):
    var value: Int
    var label: String

    def __init__(out self, value: Int, label: String):
        self.value = value
        self.label = label


def DebugLevel() -> LogLevel:
    return LogLevel(0, "DEBUG")


def InfoLevel() -> LogLevel:
    return LogLevel(1, "INFO")


def WarnLevel() -> LogLevel:
    return LogLevel(2, "WARN")


def ErrorLevel() -> LogLevel:
    return LogLevel(3, "ERROR")


def FatalLevel() -> LogLevel:
    return LogLevel(4, "FATAL")


struct LogEntry:
    var timestamp_ms: Int
    var level: LogLevel
    var message: String
    var fields: Dict[String, String]

    def __init__(out self, level: LogLevel, message: String, timestamp_ms: Int = 0):
        self.timestamp_ms = timestamp_ms
        self.level = level.copy()
        self.message = message
        self.fields = Dict[String, String]()

    def set_field(mut self, key: String, value: String):
        self.fields[key] = value

    def to_json(self) -> String:
        var result = "{"
        result += '"timestamp_ms":' + String(self.timestamp_ms)
        result += ',"level":"' + self.level.label + '"'
        result += ',"message":"' + self.message + '"'
        for item in self.fields.items():
            result += ',"' + item.key + '":"' + item.value + '"'
        result += "}"
        return result


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

    def tick(mut self, delta_ms: Int = 1):
        self.clock_ms += delta_ms

    def add_sink(mut self, sink: LogSink):
        self.core.add_sink(sink)

    def add_serializer(mut self, serializer: FieldSerializer):
        self.serializer.register_serializer(serializer)

    def with_sampler(mut self, sampler: LogSampler):
        self.sampler = sampler.copy()
        self.sampler_enabled = True

    def child(self, key: String, value: String) -> Logger:
        var logger = Logger(self.level.copy(), self.config.copy())
        logger.core = self.core.copy()
        for item in self.fields.items():
            logger.fields[item.key] = item.value
        logger.fields[key] = value
        logger.serializer = self.serializer.copy()
        logger.sampler_enabled = self.sampler_enabled
        logger.sampler = self.sampler.copy()
        return logger^

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

    def debug(mut self, message: String):
        self.log(DebugLevel(), message)

    def info(mut self, message: String):
        self.log(InfoLevel(), message)

    def warn(mut self, message: String):
        self.log(WarnLevel(), message)

    def error(mut self, message: String):
        self.log(ErrorLevel(), message)

    def fatal(mut self, message: String):
        self.log(FatalLevel(), message)

    def flush(mut self):
        self.core.flush()

    def dropped_messages(self) -> Int:
        return self.dropped_count + self.core.dropped_count()

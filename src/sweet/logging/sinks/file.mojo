# File sink

from sweet.logging.sink import LogSink


def create_file_sink(path: String) -> LogSink:
    return LogSink("file:" + path, "file", path)


def create_rotating_file_sink(path: String, max_file_size_bytes: Int) -> LogSink:
    var sink = LogSink("file:" + path, "file", path)
    sink.enable_rotation(max_file_size_bytes)
    return sink^

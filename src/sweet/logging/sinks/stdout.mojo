# Stdout sink

from sweet.logging.sink import LogSink


def create_stdout_sink() -> LogSink:
    return LogSink("stdout", "stdout", "stdout")

from sweet.logging import Logger, LogConfig, InfoLevel, LogSampler
from sweet.logging.sink import LogSink
from sweet.core.error import Error


def assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


def main() raises:
    var logger = Logger(InfoLevel(), LogConfig(enable_sampling=True, sampling_rate_percent=50))
    logger.add_sink(LogSink("memory"))
    logger.with_sampler(LogSampler(0, True))

    var child = logger.child("request_id", "req-1")
    child.info("skip-me")
    child.error("keep-me")
    logger.flush()

    assert_true(logger.core.processed_count() == 1, "error log should bypass sampling through shared worker")
    assert_true(child.core.processed_count() == 1, "child should observe same processed count")

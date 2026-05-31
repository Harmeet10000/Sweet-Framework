# Network sink metadata foundation.

from sweet.logging.sink import LogSink


def create_network_sink(endpoint: String) -> LogSink:
    return LogSink("network:" + endpoint, "network", endpoint)

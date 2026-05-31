from sweet.client import HTTPClient, ClientConfig
from sweet.logging import Logger, LogConfig, InfoLevel, create_rotating_file_sink, create_network_sink
from sweet.core.error import Error
from std.pathlib import Path


def assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


def main() raises:
    var client = HTTPClient(ClientConfig(enable_http2=True, follow_redirects=True))
    var request = client.get("http://localhost:8000/full")
    request.enable_http2()
    var response = client.execute(request)
    assert_true(response.protocol == "HTTP/2", "integration client should use http2 handler")

    var log_path = Path("/tmp/sweet.log")
    log_path.write_text("")

    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(create_rotating_file_sink("/tmp/sweet.log", 4096))
    var child = logger.child("request_id", "integration")
    child.info("integration-log")
    logger.flush()
    assert_true(logger.core.processed_count() >= 1, "shared worker should process child message")
    assert_true(child.core.processed_count() == logger.core.processed_count(), "child should share runtime state")
    assert_true("integration-log" in log_path.read_text(), "child logger should write to disk through shared file sink")

    var received_path = Path("/tmp/sweet-udp.log")
    received_path.write_text("")

    var bad_sink = create_network_sink("udp://bad-endpoint")
    bad_sink.write("payload")
    assert_true(bad_sink.error_count >= 1, "malformed UDP endpoint should increment error_count")

    var udp_logger = Logger(InfoLevel(), LogConfig())
    udp_logger.add_sink(create_network_sink("udp://localhost:15140"))
    var udp_child = udp_logger.child("request_id", "udp")
    udp_child.info("udp-log")
    udp_logger.flush()
    assert_true(udp_logger.core.processed_count() >= 1, "shared worker should process child udp message")
    assert_true(udp_child.core.processed_count() == udp_logger.core.processed_count(), "child udp logger should share runtime state")

    var received_text = ""
    for _ in range(20000):
        received_text = received_path.read_text()
        if "udp-log" in received_text:
            break

    assert_true("udp-log" in received_text, "UDP receiver should capture logger payload")
    assert_true("request_id" in received_text, "child logger metadata should travel through shared udp sink")

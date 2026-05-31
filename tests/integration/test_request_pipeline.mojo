from sweet.client import HTTPClient, ClientConfig, RequestInterceptor
from sweet.logging import Logger, LogConfig, InfoLevel, create_network_sink
from sweet.core.error import Error


def assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


def main() raises:
    var client = HTTPClient(ClientConfig(enable_pipelining=True, max_pipelined_requests=2, enable_http2=True))
    var auth = RequestInterceptor("auth")
    auth.add_header("authorization", "Bearer integration")
    client.add_request_interceptor(auth)

    var request = client.get("http://localhost:8000/pipeline")
    request.enable_pipelining()
    request.with_header("accept-encoding", "gzip")
    var response = client.execute(request)

    assert_true(response.headers["content-encoding"] == "gzip", "compression metadata should flow through")

    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(create_network_sink("udp://localhost:9001"))
    logger.info("integration-finished")
    logger.flush()
    assert_true(logger.worker.processed_count >= 1, "logger should process integration message")

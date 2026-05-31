from sweet.client import HTTPClient, ClientConfig, RequestInterceptor, ResponseInterceptor
from sweet.logging import Logger, LogConfig, FieldSerializer, InfoLevel
from sweet.logging.sink import LogSink


def assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


from sweet.core.error import Error


def test_http_client_foundation() raises:
    var client = HTTPClient(ClientConfig(enable_pipelining=True, max_pipelined_requests=3))

    var request_interceptor = RequestInterceptor("auth")
    request_interceptor.add_header("authorization", "Bearer test")
    request_interceptor.add_metadata("interceptor", "request")
    client.add_request_interceptor(request_interceptor)

    var response_interceptor = ResponseInterceptor("response-metadata")
    response_interceptor.add_metadata("observed", "true")
    client.add_response_interceptor(response_interceptor)

    var request = client.post("http://localhost:8000/demo", "hello")
    request.with_stream_chunk(" chunk-a")
    request.with_stream_chunk(" chunk-b")
    var response = client.execute(request)

    assert_true(response.status == 200, "expected simulated success")
    assert_true(response.protocol == "HTTP/1.1", "expected HTTP/1.1 protocol")
    assert_true(response.metadata["observed"] == "true", "response interceptor metadata missing")
    assert_true(response.headers["transfer-encoding"] == "chunked", "streaming request should surface chunked transfer")


def test_logger_foundation() raises:
    var logger = Logger(InfoLevel(), LogConfig(enable_sampling=True, sampling_rate_percent=100))
    var sink = LogSink("memory")
    logger.add_sink(sink)
    logger.add_serializer(FieldSerializer("secret", "***"))

    var child = logger.child("request_id", "abc123")
    var fields = Dict[String, String]()
    fields["secret"] = "token-value"
    child.log(InfoLevel(), "hello", fields)
    logger.flush()

    assert_true(logger.core.processed_count() >= 1, "shared runtime should process one log")
    assert_true(child.core.processed_count() == logger.core.processed_count(), "child should observe shared runtime state")


def test_logger_child_shares_runtime() raises:
    var logger = Logger(InfoLevel(), LogConfig())
    logger.add_sink(LogSink("memory"))

    var child = logger.child("request_id", "abc123")
    child.info("child-message")
    logger.flush()

    assert_true(logger.core.processed_count() == 1, "parent should observe child processing")
    assert_true(child.core.processed_count() == 1, "child should observe shared processing")
    assert_true(logger.dropped_messages() == child.dropped_messages(), "dropped counts should come from shared runtime")


def main() raises:
    test_http_client_foundation()
    test_logger_foundation()
    test_logger_child_shares_runtime()

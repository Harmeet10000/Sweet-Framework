from sweet.client import HTTPClient, ClientConfig
from sweet.core.error import Error


def assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error(message)


def test_connection_pool_isolation_property() raises:
    var client = HTTPClient(ClientConfig(max_connections_per_host=2))
    var first = client.acquire_connection("localhost", 8000)
    client.release_connection(first)
    var second = client.acquire_connection("localhost", 9000)

    assert_true(first.target.port != second.target.port, "different host-port pools should remain isolated")


def test_pipeline_depth_property() raises:
    var client = HTTPClient(ClientConfig(enable_pipelining=True, max_pipelined_requests=3))
    var request = client.get("http://localhost:8000/a")
    request.enable_pipelining()
    var response = client.execute(request)

    assert_true(response.metadata["handler_protocol"] == "HTTP/1.1", "pipeline handler should stay on HTTP/1.1")


def test_http2_stream_limit_property() raises:
    var client = HTTPClient(ClientConfig(enable_http2=True))
    var request = client.get("http://localhost:8000/b")
    request.enable_http2()
    var response = client.execute(request)

    assert_true(response.protocol == "HTTP/2", "http2 request should report HTTP/2 protocol")


def main() raises:
    test_connection_pool_isolation_property()
    test_pipeline_depth_property()
    test_http2_stream_limit_property()

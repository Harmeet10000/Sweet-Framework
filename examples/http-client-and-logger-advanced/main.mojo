from sweet.client import HTTPClient, ClientConfig, RequestInterceptor, ResponseInterceptor
from sweet.logging import Logger, LogConfig, InfoLevel, create_stdout_sink, create_network_sink, create_rotating_file_sink


def main() raises:
    var client = HTTPClient(ClientConfig(enable_http2=True, enable_pipelining=True, max_pipelined_requests=3))

    var auth = RequestInterceptor("auth")
    auth.add_header("authorization", "Bearer advanced")
    client.add_request_interceptor(auth)

    var response_meta = ResponseInterceptor("meta")
    response_meta.add_metadata("advanced", "true")
    client.add_response_interceptor(response_meta)

    var request = client.post("http://localhost:8443/submit", "payload")
    request.enable_http2()
    request.with_header("accept-encoding", "br")
    request.with_stream_chunk("chunk-1")
    request.with_stream_chunk("chunk-2")
    var response = client.execute(request)

    var logger = Logger(InfoLevel(), LogConfig(enable_sampling=True, sampling_rate_percent=100))
    logger.add_sink(create_stdout_sink())
    logger.add_sink(create_network_sink("tcp://localhost:1514"))
    logger.add_sink(create_rotating_file_sink("/tmp/sweet-advanced.log", 4096))

    var fields = Dict[String, String]()
    fields["status"] = String(response.status)
    fields["protocol"] = response.protocol
    fields["advanced"] = response.metadata["advanced"]
    logger.log(InfoLevel(), "advanced example complete", fields)
    logger.flush()

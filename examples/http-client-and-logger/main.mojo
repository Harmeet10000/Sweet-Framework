from sweet.client import HTTPClient, ClientConfig, RequestInterceptor
from sweet.logging import Logger, LogConfig, InfoLevel, create_stdout_sink


def main() raises:
    var client = HTTPClient(ClientConfig(enable_pipelining=True, max_pipelined_requests=2))
    var auth = RequestInterceptor("auth")
    auth.add_header("authorization", "Bearer demo")
    client.add_request_interceptor(auth)

    var request = client.get("http://localhost:8000/hello")
    request.with_metadata("feature", "http-client-and-logger-enhancement")
    var response = client.execute(request)

    var logger = Logger(InfoLevel(), LogConfig(enable_sampling=True, sampling_rate_percent=100))
    logger.add_sink(create_stdout_sink())

    var fields = Dict[String, String]()
    fields["status"] = String(response.status)
    fields["protocol"] = response.protocol
    logger.log(InfoLevel(), "client execution finished", fields)
    logger.flush()

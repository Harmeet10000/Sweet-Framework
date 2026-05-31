from sweet.client import HTTPClient, ClientConfig
from sweet.logging import Logger, LogConfig, InfoLevel


def main() raises:
    var client = HTTPClient(ClientConfig(enable_pipelining=True, max_pipelined_requests=4))
    var logger = Logger(InfoLevel(), LogConfig())

    for i in range(10):
        var response = client.get_response("http://localhost:8000/bench-" + String(i))
        var fields = Dict[String, String]()
        fields["iteration"] = String(i)
        fields["status"] = String(response.status)
        logger.log(InfoLevel(), "benchmark-iteration", fields)

    logger.flush()

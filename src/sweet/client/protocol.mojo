# Protocol handler abstractions for the HTTP client roadmap.

from sweet.client.client import ClientRequest, ClientResponse


struct ProtocolFeatures(Copyable):
    var protocol_name: String
    var supports_pipelining: Bool
    var supports_multiplexing: Bool
    var max_concurrent_requests: Int
    var supports_server_push: Bool
    var supports_flow_control: Bool

    def __init__(
        out self,
        protocol_name: String,
        supports_pipelining: Bool = False,
        supports_multiplexing: Bool = False,
        max_concurrent_requests: Int = 1,
        supports_server_push: Bool = False,
        supports_flow_control: Bool = False,
    ):
        self.protocol_name = protocol_name
        self.supports_pipelining = supports_pipelining
        self.supports_multiplexing = supports_multiplexing
        self.max_concurrent_requests = max_concurrent_requests
        self.supports_server_push = supports_server_push
        self.supports_flow_control = supports_flow_control


struct HTTP1Pipeline(Copyable):
    var max_depth: Int
    var queued_paths: List[String]
    var response_order: List[String]

    def __init__(out self, max_depth: Int = 1):
        self.max_depth = max_depth
        self.queued_paths = List[String]()
        self.response_order = List[String]()

    def can_accept(self) -> Bool:
        return len(self.queued_paths) < self.max_depth

    def enqueue(mut self, path: String) -> Bool:
        if not self.can_accept():
            return False
        self.queued_paths.append(path)
        return True

    def complete(mut self, path: String):
        self.response_order.append(path)


struct HTTP2Multiplexer(Copyable):
    var max_streams: Int
    var active_streams: Int
    var goaway_received: Bool

    def __init__(out self, max_streams: Int = 100):
        self.max_streams = max_streams
        self.active_streams = 0
        self.goaway_received = False

    def can_open_stream(self) -> Bool:
        return not self.goaway_received and self.active_streams < self.max_streams

    def open_stream(mut self) -> Bool:
        if not self.can_open_stream():
            return False
        self.active_streams += 1
        return True

    def close_stream(mut self):
        if self.active_streams > 0:
            self.active_streams -= 1

    def receive_goaway(mut self):
        self.goaway_received = True


struct HTTP2FlowControl(Copyable):
    var connection_window: Int
    var stream_window: Int

    def __init__(out self, connection_window: Int = 65535, stream_window: Int = 65535):
        self.connection_window = connection_window
        self.stream_window = stream_window

    def can_send(self, bytes: Int) -> Bool:
        return bytes <= self.connection_window and bytes <= self.stream_window

    def consume(mut self, bytes: Int):
        self.connection_window -= bytes
        self.stream_window -= bytes
        if self.connection_window < 0:
            self.connection_window = 0
        if self.stream_window < 0:
            self.stream_window = 0

    def update(mut self, bytes: Int):
        self.connection_window += bytes
        self.stream_window += bytes


struct ProtocolHandler(Copyable):
    var features: ProtocolFeatures
    var pipeline: HTTP1Pipeline
    var multiplexer: HTTP2Multiplexer
    var flow_control: HTTP2FlowControl

    def __init__(out self, features: ProtocolFeatures):
        self.features = features.copy()
        self.pipeline = HTTP1Pipeline(features.max_concurrent_requests)
        self.multiplexer = HTTP2Multiplexer(features.max_concurrent_requests)
        self.flow_control = HTTP2FlowControl()

    def send_request(mut self, request: ClientRequest) -> ClientResponse:
        var response = ClientResponse(200)
        response.protocol = self.features.protocol_name
        response.metadata["handler_protocol"] = self.features.protocol_name
        response.body = request.body_payload()
        if self.features.supports_pipelining:
            _ = self.pipeline.enqueue(request.url)
            self.pipeline.complete(request.url)
            response.metadata["pipeline_depth"] = String(self.pipeline.max_depth)
        if self.features.supports_multiplexing:
            _ = self.multiplexer.open_stream()
            response.metadata["active_streams"] = String(self.multiplexer.active_streams)
            self.multiplexer.close_stream()
        return response^


def create_http1_handler(max_pipeline_depth: Int = 1) -> ProtocolHandler:
    return ProtocolHandler(ProtocolFeatures("HTTP/1.1", max_pipeline_depth > 1, False, max_pipeline_depth, False, False))


def create_http2_handler(max_streams: Int = 100) -> ProtocolHandler:
    return ProtocolHandler(ProtocolFeatures("HTTP/2", False, True, max_streams, True, True))

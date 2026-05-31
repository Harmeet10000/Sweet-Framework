# HTTP client foundations for the enhancement spec.

from sweet.client.config import ClientConfig, PoolConfig, DNSConfig
from sweet.client.interceptor import RequestInterceptor, ResponseInterceptor, ensure_required_header
from sweet.client.pool import HostPort, Connection, ConnectionPool, ConnectionMetrics
from sweet.client.dns import DNSResolver
from sweet.client.protocol import ProtocolHandler, create_http1_handler, create_http2_handler
from sweet.client.retry import RetryPolicy
from sweet.core.error import Error
from sweet.core.result import Result, Ok, Err


struct ClientTimeouts(Copyable):
    var connect_timeout_ms: Int
    var request_timeout_ms: Int
    var idle_timeout_ms: Int
    var dns_timeout_ms: Int

    def __init__(out self, connect_timeout_ms: Int = 1_000, request_timeout_ms: Int = 5_000, idle_timeout_ms: Int = 30_000, dns_timeout_ms: Int = 500):
        self.connect_timeout_ms = connect_timeout_ms
        self.request_timeout_ms = request_timeout_ms
        self.idle_timeout_ms = idle_timeout_ms
        self.dns_timeout_ms = dns_timeout_ms


struct StreamingBody(Copyable):
    var chunks: List[String]
    var next_index: Int
    var chunked_transfer: Bool

    def __init__(out self):
        self.chunks = List[String]()
        self.next_index = 0
        self.chunked_transfer = False

    def append_chunk(mut self, chunk: String):
        self.chunks.append(chunk)

    def has_next(self) -> Bool:
        return self.next_index < len(self.chunks)

    def next_chunk(mut self) -> Optional[String]:
        if not self.has_next():
            return None
        var chunk = self.chunks[self.next_index]
        self.next_index += 1
        return chunk

    def rewind(mut self):
        self.next_index = 0

    def to_string(self) -> String:
        var result = ""
        for i in range(len(self.chunks)):
            result += self.chunks[i]
        return result


struct ClientRequest(Movable):
    var method: String
    var url: String
    var headers: Dict[String, String]
    var body: String
    var timeout_ms: Int
    var connect_timeout_ms: Int
    var idle_timeout_ms: Int
    var metadata: Dict[String, String]
    var streaming_body: StreamingBody
    var max_retries: Int
    var allow_non_idempotent_retry: Bool
    var follow_redirects: Bool
    var use_http2: Bool
    var use_pipelining: Bool

    def __init__(out self, method: String, url: String):
        self.method = method
        self.url = url
        self.headers = Dict[String, String]()
        self.body = ""
        self.timeout_ms = 5_000
        self.connect_timeout_ms = 1_000
        self.idle_timeout_ms = 30_000
        self.metadata = Dict[String, String]()
        self.streaming_body = StreamingBody()
        self.max_retries = 3
        self.allow_non_idempotent_retry = False
        self.follow_redirects = True
        self.use_http2 = False
        self.use_pipelining = False

    def with_header(mut self, key: String, value: String):
        self.headers[key] = value

    def with_body(mut self, body: String):
        self.body = body

    def with_timeout(mut self, timeout_ms: Int):
        self.timeout_ms = timeout_ms

    def with_connect_timeout(mut self, timeout_ms: Int):
        self.connect_timeout_ms = timeout_ms

    def with_idle_timeout(mut self, timeout_ms: Int):
        self.idle_timeout_ms = timeout_ms

    def with_metadata(mut self, key: String, value: String):
        self.metadata[key] = value

    def with_stream_chunk(mut self, chunk: String):
        self.streaming_body.chunked_transfer = True
        self.streaming_body.append_chunk(chunk)

    def enable_http2(mut self):
        self.use_http2 = True

    def enable_pipelining(mut self):
        self.use_pipelining = True

    def allow_retry_for_non_idempotent(mut self):
        self.allow_non_idempotent_retry = True

    def set_max_retries(mut self, max_retries: Int):
        self.max_retries = max_retries

    def body_payload(self) -> String:
        if len(self.body) > 0:
            return self.body
        return self.streaming_body.to_string()


struct ClientResponse(Movable):
    var status: Int
    var headers: Dict[String, String]
    var body: String
    var protocol: String
    var metadata: Dict[String, String]
    var body_chunks: List[String]
    var stream_complete: Bool

    def __init__(out self, status: Int = 200):
        self.status = status
        self.headers = Dict[String, String]()
        self.body = ""
        self.protocol = "HTTP/1.1"
        self.metadata = Dict[String, String]()
        self.body_chunks = List[String]()
        self.stream_complete = True

    def is_success(self) -> Bool:
        return self.status >= 200 and self.status < 300

    def is_redirect(self) -> Bool:
        return self.status >= 300 and self.status < 400

    def is_error(self) -> Bool:
        return self.status >= 400

    def append_chunk(mut self, chunk: String):
        self.body_chunks.append(chunk)
        self.body += chunk
        self.stream_complete = False

    def finish_stream(mut self):
        self.stream_complete = True


struct HTTPClient:
    var config: ClientConfig
    var default_headers: Dict[String, String]
    var pool: ConnectionPool
    var dns: DNSResolver
    var retry_policy: RetryPolicy
    var request_interceptors: List[RequestInterceptor]
    var response_interceptors: List[ResponseInterceptor]
    var clock_ms: Int
    var redirect_count: Int

    def __init__(out self, config: ClientConfig = ClientConfig()):
        self.config = config.copy()
        self.default_headers = Dict[String, String]()
        self.default_headers["User-Agent"] = "SweetHTTPClient/0.1.0"
        self.pool = ConnectionPool(PoolConfig(config.max_connections_per_host, config.idle_timeout_ms, config.max_pending_requests_per_host))
        self.dns = DNSResolver(DNSConfig(60, 10, 128, config.dns_timeout_ms))
        self.retry_policy = RetryPolicy()
        self.request_interceptors = List[RequestInterceptor]()
        self.response_interceptors = List[ResponseInterceptor]()
        self.clock_ms = 0
        self.redirect_count = 0

    def tick(mut self, delta_ms: Int = 1):
        self.clock_ms += delta_ms

    def now_ms(self) -> Int:
        return self.clock_ms

    def configure_retry_policy(mut self, retry_policy: RetryPolicy):
        self.retry_policy = retry_policy.copy()

    def add_request_interceptor(mut self, interceptor: RequestInterceptor):
        self.request_interceptors.append(interceptor.copy())

    def add_response_interceptor(mut self, interceptor: ResponseInterceptor):
        self.response_interceptors.append(interceptor.copy())

    def apply_request_interceptors(mut self, req: ClientRequest) raises -> ClientRequest:
        var updated = ClientRequest(req.method, req.url)
        updated.body = req.body
        updated.timeout_ms = req.timeout_ms
        updated.connect_timeout_ms = req.connect_timeout_ms
        updated.idle_timeout_ms = req.idle_timeout_ms
        updated.streaming_body = req.streaming_body.copy()
        updated.max_retries = req.max_retries
        updated.allow_non_idempotent_retry = req.allow_non_idempotent_retry
        updated.follow_redirects = req.follow_redirects
        updated.use_http2 = req.use_http2
        updated.use_pipelining = req.use_pipelining
        for item in req.headers.items():
            updated.headers[item.key] = item.value
        for item in req.metadata.items():
            updated.metadata[item.key] = item.value
        for i in range(len(self.request_interceptors)):
            var interceptor = self.request_interceptors[i].copy()
            ensure_required_header(updated.headers, interceptor.required_header, interceptor.abort_message)
            for item in interceptor.headers_to_add.items():
                updated.headers[item.key] = item.value
            for item in interceptor.metadata_to_add.items():
                updated.metadata[item.key] = item.value
        return updated^

    def apply_response_interceptors(mut self, response: ClientResponse) raises -> ClientResponse:
        var updated = ClientResponse(response.status)
        updated.body = response.body
        updated.protocol = response.protocol
        updated.stream_complete = response.stream_complete
        for item in response.headers.items():
            updated.headers[item.key] = item.value
        for item in response.metadata.items():
            updated.metadata[item.key] = item.value
        for i in range(len(response.body_chunks)):
            updated.body_chunks.append(response.body_chunks[i])
        for i in range(len(self.response_interceptors)):
            var interceptor = self.response_interceptors[i].copy()
            if interceptor.force_error_status_at_or_above > 0 and updated.status >= interceptor.force_error_status_at_or_above:
                raise Error("response interceptor aborted")
            for item in interceptor.metadata_to_add.items():
                updated.metadata[item.key] = item.value
        return updated^

    def new_request(self, method: String, url: String) -> ClientRequest:
        var request = ClientRequest(method, url)
        request.timeout_ms = self.config.request_timeout_ms
        request.connect_timeout_ms = self.config.connect_timeout_ms
        request.idle_timeout_ms = self.config.idle_timeout_ms
        request.follow_redirects = self.config.follow_redirects
        request.use_http2 = self.config.enable_http2
        request.use_pipelining = self.config.enable_pipelining
        for item in self.default_headers.items():
            request.headers[item.key] = item.value
        return request^

    def get(self, url: String) -> ClientRequest:
        return self.new_request("GET", url)

    def post(self, url: String, body: String) -> ClientRequest:
        var request = self.new_request("POST", url)
        request.body = body
        return request^

    def resolve_host(mut self, host: String) -> List[String]:
        return self.dns.resolve(host, self.now_ms())

    def acquire_connection(mut self, host: String, port: Int, protocol: String = "HTTP/1.1") raises -> Connection:
        _ = self.dns.resolve(host, self.now_ms())
        var pipeline_depth = 1
        if self.config.enable_pipelining and protocol == "HTTP/1.1":
            pipeline_depth = self.config.max_pipelined_requests
        return self.pool.acquire(host, port, protocol, self.now_ms(), pipeline_depth)

    def release_connection(mut self, conn: Connection):
        self.pool.release(conn, self.now_ms())

    def remove_connection(mut self, conn: Connection):
        self.pool.remove(conn)

    def pool_metrics(self) -> ConnectionMetrics:
        return self.pool.stats()

    def cleanup_idle_connections(mut self) -> Int:
        return self.pool.cleanup_idle(self.now_ms())

    def make_protocol_handler(self, request: ClientRequest) -> ProtocolHandler:
        if request.use_http2:
            return create_http2_handler(100)
        var pipeline_depth = 1
        if request.use_pipelining:
            pipeline_depth = self.config.max_pipelined_requests
        return create_http1_handler(pipeline_depth)

    def apply_redirect_and_compression_metadata(mut self, request: ClientRequest, mut response: ClientResponse):
        if request.follow_redirects and "location" in response.headers:
            self.redirect_count += 1
            response.metadata["redirect_count"] = String(self.redirect_count)
        if "accept-encoding" in request.headers and "content-encoding" in response.headers:
            for item in response.headers.items():
                if item.key == "content-encoding":
                    response.metadata["compression"] = item.value

    def execute_async(mut self, req: ClientRequest) -> Result[ClientResponse, Error]:
        return self.execute_result(req)

    def get_async(mut self, url: String) -> Result[ClientResponse, Error]:
        return self.execute_async(self.get(url))

    def post_async(mut self, url: String, body: String) -> Result[ClientResponse, Error]:
        return self.execute_async(self.post(url, body))

    def execute(mut self, req: ClientRequest) raises -> ClientResponse:
        self.tick(1)
        var request = self.apply_request_interceptors(req)
        var protocol = "HTTP/1.1"
        if request.use_http2:
            protocol = "HTTP/2"

        var host = "localhost"
        var port = 80
        if "://" in request.url:
            var url_parts = request.url.split("://")
            if len(url_parts) > 1:
                host = String(url_parts[1])
        if "/" in host:
            host = String(host.split("/")[0])
        if ":" in host:
            var host_port = host.split(":")
            host = String(host_port[0])
            if len(host_port) > 1:
                port = Int(String(host_port[1]))

        var conn = self.acquire_connection(host, port, protocol)
        var handler = self.make_protocol_handler(request)
        var response = handler.send_request(request)
        response.protocol = protocol
        response.headers["x-sweet-client"] = "simulated"
        response.metadata["host"] = host
        response.metadata["connection_id"] = String(conn.id)
        if request.streaming_body.chunked_transfer:
            response.headers["transfer-encoding"] = "chunked"
            response.body = request.body_payload()
            response.finish_stream()
        if "content-encoding" not in response.headers and "accept-encoding" in request.headers:
            response.headers["content-encoding"] = request.headers["accept-encoding"]
        self.apply_redirect_and_compression_metadata(request, response)
        response.metadata["retryable"] = String(self.retry_policy.should_retry(request.method, 0, response.status, False))
        response = self.apply_response_interceptors(response)
        self.release_connection(conn)
        return response^

    def execute_result(mut self, req: ClientRequest) -> Result[ClientResponse, Error]:
        try:
            return Ok[ClientResponse, Error](self.execute(req))
        except err:
            return Err[ClientResponse, Error](err)

    def get_response(mut self, url: String) raises -> ClientResponse:
        var request = self.get(url)
        return self.execute(request)

    def post_response(mut self, url: String, body: String) raises -> ClientResponse:
        var request = self.post(url, body)
        return self.execute(request)

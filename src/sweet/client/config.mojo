# HTTP client configuration primitives.

struct ClientConfig(Copyable):
    var connect_timeout_ms: Int
    var request_timeout_ms: Int
    var idle_timeout_ms: Int
    var dns_timeout_ms: Int
    var max_connections_per_host: Int
    var max_pending_requests_per_host: Int
    var max_pipelined_requests: Int
    var enable_pipelining: Bool
    var enable_http2: Bool
    var follow_redirects: Bool

    def __init__(
        out self,
        connect_timeout_ms: Int = 1_000,
        request_timeout_ms: Int = 5_000,
        idle_timeout_ms: Int = 30_000,
        dns_timeout_ms: Int = 500,
        max_connections_per_host: Int = 8,
        max_pending_requests_per_host: Int = 64,
        max_pipelined_requests: Int = 4,
        enable_pipelining: Bool = False,
        enable_http2: Bool = False,
        follow_redirects: Bool = True,
    ):
        self.connect_timeout_ms = connect_timeout_ms
        self.request_timeout_ms = request_timeout_ms
        self.idle_timeout_ms = idle_timeout_ms
        self.dns_timeout_ms = dns_timeout_ms
        self.max_connections_per_host = max_connections_per_host
        self.max_pending_requests_per_host = max_pending_requests_per_host
        self.max_pipelined_requests = max_pipelined_requests
        self.enable_pipelining = enable_pipelining
        self.enable_http2 = enable_http2
        self.follow_redirects = follow_redirects


struct PoolConfig(Copyable):
    var max_connections_per_host: Int
    var idle_timeout_ms: Int
    var max_pending_requests: Int
    var cleanup_interval_ms: Int

    def __init__(
        out self,
        max_connections_per_host: Int = 8,
        idle_timeout_ms: Int = 30_000,
        max_pending_requests: Int = 64,
        cleanup_interval_ms: Int = 5_000,
    ):
        self.max_connections_per_host = max_connections_per_host
        self.idle_timeout_ms = idle_timeout_ms
        self.max_pending_requests = max_pending_requests
        self.cleanup_interval_ms = cleanup_interval_ms


struct DNSConfig(Copyable):
    var default_ttl_seconds: Int
    var negative_ttl_seconds: Int
    var max_cache_size: Int
    var resolution_timeout_ms: Int

    def __init__(
        out self,
        default_ttl_seconds: Int = 60,
        negative_ttl_seconds: Int = 10,
        max_cache_size: Int = 128,
        resolution_timeout_ms: Int = 500,
    ):
        self.default_ttl_seconds = default_ttl_seconds
        self.negative_ttl_seconds = negative_ttl_seconds
        self.max_cache_size = max_cache_size
        self.resolution_timeout_ms = resolution_timeout_ms

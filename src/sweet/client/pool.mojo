# Connection pool foundations for the HTTP client slice.

from sweet.core.error import Error
from sweet.client.config import PoolConfig

struct HostPort(Copyable):
    var host: String
    var port: Int

    def __init__(out self, host: String, port: Int):
        self.host = host
        self.port = port

    def key(self) -> String:
        return self.host + ":" + String(self.port)


struct ConnectionMetrics(Copyable):
    var created: Int
    var reused: Int
    var closed: Int
    var errors: Int

    def __init__(out self):
        self.created = 0
        self.reused = 0
        self.closed = 0
        self.errors = 0


struct Connection(Copyable):
    var id: Int
    var target: HostPort
    var protocol: String
    var is_active: Bool
    var request_count: Int
    var created_at_ms: Int
    var last_used_at_ms: Int
    var is_healthy: Bool
    var accepts_pipelining: Bool
    var max_pipelined_requests: Int

    def __init__(out self, id: Int, target: HostPort, protocol: String = "HTTP/1.1", now_ms: Int = 0):
        self.id = id
        self.target = target.copy()
        self.protocol = protocol
        self.is_active = False
        self.request_count = 0
        self.created_at_ms = now_ms
        self.last_used_at_ms = now_ms
        self.is_healthy = True
        self.accepts_pipelining = protocol == "HTTP/1.1"
        self.max_pipelined_requests = 1

    def mark_active(mut self):
        self.is_active = True
        self.request_count += 1

    def mark_idle(mut self, now_ms: Int = 0):
        self.is_active = False
        self.last_used_at_ms = now_ms

    def mark_failed(mut self):
        self.is_healthy = False

    def configure_pipelining(mut self, enabled: Bool, max_requests: Int):
        self.accepts_pipelining = enabled
        if enabled and max_requests > 1:
            self.max_pipelined_requests = max_requests
        else:
            self.max_pipelined_requests = 1

    def is_idle_expired(self, now_ms: Int, idle_timeout_ms: Int) -> Bool:
        if self.is_active:
            return False
        return now_ms - self.last_used_at_ms >= idle_timeout_ms


struct HostPool(Copyable):
    var target: HostPort
    var idle_connections: List[Connection]
    var active_connections: List[Connection]
    var max_connections: Int
    var pending_requests: Int
    var max_pending_requests: Int

    def __init__(out self, target: HostPort, max_connections: Int = 8, max_pending_requests: Int = 64):
        self.target = target.copy()
        self.idle_connections = List[Connection]()
        self.active_connections = List[Connection]()
        self.max_connections = max_connections
        self.pending_requests = 0
        self.max_pending_requests = max_pending_requests

    def total_connections(self) -> Int:
        return len(self.idle_connections) + len(self.active_connections)

    def has_capacity(self) -> Bool:
        return self.total_connections() < self.max_connections

    def pop_idle(mut self, now_ms: Int = 0) -> Optional[Connection]:
        if len(self.idle_connections) == 0:
            return None
        var conn = self.idle_connections.pop()
        conn.mark_active()
        conn.last_used_at_ms = now_ms
        self.active_connections.append(conn.copy())
        return conn^

    def add_new_connection(mut self, conn: Connection):
        self.active_connections.append(conn.copy())

    def release_connection(mut self, connection_id: Int, now_ms: Int = 0) -> Bool:
        for i in range(len(self.active_connections)):
            if self.active_connections[i].id == connection_id:
                var conn = self.active_connections.pop(i)
                conn.mark_idle(now_ms)
                self.idle_connections.append(conn.copy())
                return True
        return False

    def enqueue_request(mut self) -> Bool:
        if self.pending_requests >= self.max_pending_requests:
            return False
        self.pending_requests += 1
        return True

    def consume_pending_request(mut self):
        if self.pending_requests > 0:
            self.pending_requests -= 1

    def cleanup_idle(mut self, now_ms: Int, idle_timeout_ms: Int) -> Int:
        var removed = 0
        var kept = List[Connection]()
        for i in range(len(self.idle_connections)):
            if self.idle_connections[i].is_idle_expired(now_ms, idle_timeout_ms):
                removed += 1
            else:
                kept.append(self.idle_connections[i].copy())
        self.idle_connections = kept
        return removed

    def remove_connection(mut self, connection_id: Int) -> Bool:
        for i in range(len(self.active_connections)):
            if self.active_connections[i].id == connection_id:
                _ = self.active_connections.pop(i)
                return True
        for i in range(len(self.idle_connections)):
            if self.idle_connections[i].id == connection_id:
                _ = self.idle_connections.pop(i)
                return True
        return False


struct ConnectionPool:
    var pools: List[HostPool]
    var metrics: ConnectionMetrics
    var next_connection_id: Int
    var config: PoolConfig

    def __init__(out self, config: PoolConfig = PoolConfig()):
        self.pools = List[HostPool]()
        self.metrics = ConnectionMetrics()
        self.next_connection_id = 1
        self.config = config.copy()

    def find_pool_index(self, host: String, port: Int) -> Int:
        for i in range(len(self.pools)):
            if self.pools[i].target.host == host and self.pools[i].target.port == port:
                return i
        return -1

    def get_or_create_pool_index(mut self, host: String, port: Int) -> Int:
        var target = HostPort(host, port)
        var existing_index = self.find_pool_index(host, port)
        if existing_index >= 0:
            return existing_index
        self.pools.append(HostPool(target, self.config.max_connections_per_host, self.config.max_pending_requests))
        return len(self.pools) - 1

    def register_created(mut self) -> Int:
        var id = self.next_connection_id
        self.next_connection_id += 1
        self.metrics.created += 1
        return id

    def acquire(mut self, host: String, port: Int, protocol: String = "HTTP/1.1", now_ms: Int = 0, pipeline_depth: Int = 1) raises -> Connection:
        var target = HostPort(host, port)
        var key = target.key()
        var pool_index = self.get_or_create_pool_index(host, port)
        var pool = self.pools[pool_index].copy()
        var reused = pool.pop_idle(now_ms)
        if reused is not None:
            self.metrics.reused += 1
            pool.consume_pending_request()
            self.pools[pool_index] = pool.copy()
            return reused.value().copy()

        if not pool.has_capacity():
            if not pool.enqueue_request():
                self.metrics.errors += 1
                self.pools[pool_index] = pool.copy()
                raise Error("Connection pool queue exhausted for " + key)
            self.metrics.errors += 1
            self.pools[pool_index] = pool.copy()
            raise Error("Connection pool exhausted for " + key)

        var connection_id = self.register_created()
        var conn = Connection(connection_id, target, protocol, now_ms)
        conn.configure_pipelining(protocol == "HTTP/1.1" and pipeline_depth > 1, pipeline_depth)
        conn.mark_active()
        pool.add_new_connection(conn)
        pool.consume_pending_request()
        self.pools[pool_index] = pool.copy()
        return conn^

    def release(mut self, conn: Connection, now_ms: Int = 0):
        var pool_index = self.find_pool_index(conn.target.host, conn.target.port)
        if pool_index < 0:
            return
        var pool = self.pools[pool_index].copy()
        _ = pool.release_connection(conn.id, now_ms)
        self.pools[pool_index] = pool.copy()

    def remove(mut self, conn: Connection):
        var pool_index = self.find_pool_index(conn.target.host, conn.target.port)
        if pool_index < 0:
            return
        var pool = self.pools[pool_index].copy()
        if pool.remove_connection(conn.id):
            self.metrics.closed += 1
        else:
            self.metrics.errors += 1
        self.pools[pool_index] = pool.copy()

    def cleanup_idle(mut self, now_ms: Int) -> Int:
        var removed = 0
        for i in range(len(self.pools)):
            var pool = self.pools[i].copy()
            var pool_removed = pool.cleanup_idle(now_ms, self.config.idle_timeout_ms)
            removed += pool_removed
            self.metrics.closed += pool_removed
            self.pools[i] = pool.copy()
        return removed

    def stats(self) -> ConnectionMetrics:
        return self.metrics.copy()

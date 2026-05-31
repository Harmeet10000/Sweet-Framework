# DNS foundation for the HTTP client slice.

from sweet.client.config import DNSConfig

struct DNSEntry(Copyable):
    var hostname: String
    var addresses: List[String]
    var ttl_seconds: Int
    var cached_at_ms: Int
    var last_accessed_at_ms: Int
    var negative: Bool

    def __init__(out self, hostname: String, addresses: List[String], ttl_seconds: Int = 60, cached_at_ms: Int = 0, negative: Bool = False):
        self.hostname = hostname
        self.addresses = addresses.copy()
        self.ttl_seconds = ttl_seconds
        self.cached_at_ms = cached_at_ms
        self.last_accessed_at_ms = cached_at_ms
        self.negative = negative

    def is_expired(self, now_ms: Int) -> Bool:
        return now_ms - self.cached_at_ms >= self.ttl_seconds * 1000


struct DNSResolver:
    var cache: List[DNSEntry]
    var config: DNSConfig

    def __init__(out self, config: DNSConfig = DNSConfig()):
        self.cache = List[DNSEntry]()
        self.config = config.copy()

    def find_entry_index(self, hostname: String) -> Int:
        for i in range(len(self.cache)):
            if self.cache[i].hostname == hostname:
                return i
        return -1

    def touch_entry(mut self, index: Int, now_ms: Int):
        var entry = self.cache[index].copy()
        entry.last_accessed_at_ms = now_ms
        self.cache[index] = entry.copy()

    def evict_lru_if_needed(mut self):
        if len(self.cache) < self.config.max_cache_size:
            return
        if len(self.cache) == 0:
            return
        var oldest_index = 0
        var oldest_access = self.cache[0].last_accessed_at_ms
        for i in range(1, len(self.cache)):
            if self.cache[i].last_accessed_at_ms < oldest_access:
                oldest_access = self.cache[i].last_accessed_at_ms
                oldest_index = i
        _ = self.cache.pop(oldest_index)

    def resolve(mut self, hostname: String, now_ms: Int = 0) -> List[String]:
        var existing_index = self.find_entry_index(hostname)
        if existing_index >= 0:
            if not self.cache[existing_index].is_expired(now_ms):
                self.touch_entry(existing_index, now_ms)
                return self.cache[existing_index].addresses.copy()
            _ = self.cache.pop(existing_index)

        var fallback = List[String]()
        if hostname == "localhost":
            fallback.append("127.0.0.1")
        else:
            fallback.append(hostname)

        self.evict_lru_if_needed()
        self.cache.append(DNSEntry(hostname, fallback, self.config.default_ttl_seconds, now_ms))
        return fallback^

    def resolve_negative(mut self, hostname: String, now_ms: Int = 0):
        self.evict_lru_if_needed()
        var empty = List[String]()
        self.cache.append(DNSEntry(hostname, empty, self.config.negative_ttl_seconds, now_ms, True))

    def put(mut self, hostname: String, addresses: List[String], ttl_seconds: Int = 60, now_ms: Int = 0):
        var existing_index = self.find_entry_index(hostname)
        var entry = DNSEntry(hostname, addresses, ttl_seconds, now_ms)
        if existing_index >= 0:
            self.cache[existing_index] = entry.copy()
        else:
            self.evict_lru_if_needed()
            self.cache.append(entry.copy())

    def invalidate(mut self, hostname: String):
        var existing_index = self.find_entry_index(hostname)
        if existing_index >= 0:
            _ = self.cache.pop(existing_index)

# Retry policy with exponential backoff foundations.

struct RetryPolicy(Copyable):
    var max_attempts: Int
    var base_delay_ms: Int
    var max_delay_ms: Int
    var jitter_percent: Int
    var retry_non_idempotent: Bool
    var retry_status_codes: List[Int]

    def __init__(
        out self,
        max_attempts: Int = 3,
        base_delay_ms: Int = 100,
        max_delay_ms: Int = 2_000,
        jitter_percent: Int = 10,
        retry_non_idempotent: Bool = False,
    ):
        self.max_attempts = max_attempts
        self.base_delay_ms = base_delay_ms
        self.max_delay_ms = max_delay_ms
        self.jitter_percent = jitter_percent
        self.retry_non_idempotent = retry_non_idempotent
        self.retry_status_codes = List[Int]()
        self.retry_status_codes.append(408)
        self.retry_status_codes.append(425)
        self.retry_status_codes.append(429)
        self.retry_status_codes.append(500)
        self.retry_status_codes.append(502)
        self.retry_status_codes.append(503)
        self.retry_status_codes.append(504)

    def add_retry_status(mut self, status: Int):
        self.retry_status_codes.append(status)

    def is_idempotent_method(self, method: String) -> Bool:
        return method == "GET" or method == "HEAD" or method == "PUT" or method == "DELETE" or method == "OPTIONS"

    def should_retry(self, method: String, attempt: Int, status: Int = 0, had_connection_error: Bool = False) -> Bool:
        if attempt >= self.max_attempts:
            return False
        if not self.retry_non_idempotent and not self.is_idempotent_method(method):
            return False
        if had_connection_error:
            return True
        for i in range(len(self.retry_status_codes)):
            if self.retry_status_codes[i] == status:
                return True
        return False

    def backoff_delay_ms(self, attempt: Int) -> Int:
        var delay = self.base_delay_ms
        for _ in range(attempt):
            delay *= 2
            if delay >= self.max_delay_ms:
                return self.max_delay_ms
        if delay > self.max_delay_ms:
            return self.max_delay_ms
        return delay

    def jittered_delay_ms(self, attempt: Int) -> Int:
        var base = self.backoff_delay_ms(attempt)
        var jitter = (base * self.jitter_percent) // 100
        return base + (attempt % (jitter + 1))

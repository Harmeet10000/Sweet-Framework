# Logging configuration primitives.

struct LogConfig(Copyable):
    var queue_size: Int
    var drop_on_full: Bool
    var minimum_level: Int
    var enable_sampling: Bool
    var sampling_rate_percent: Int
    var deterministic_sampling: Bool
    var flush_interval_ms: Int

    def __init__(
        out self,
        queue_size: Int = 1024,
        drop_on_full: Bool = True,
        minimum_level: Int = 1,
        enable_sampling: Bool = False,
        sampling_rate_percent: Int = 100,
        deterministic_sampling: Bool = True,
        flush_interval_ms: Int = 100,
    ):
        self.queue_size = queue_size
        self.drop_on_full = drop_on_full
        self.minimum_level = minimum_level
        self.enable_sampling = enable_sampling
        self.sampling_rate_percent = sampling_rate_percent
        self.deterministic_sampling = deterministic_sampling
        self.flush_interval_ms = flush_interval_ms

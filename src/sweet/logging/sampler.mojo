# Log sampling support.

from sweet.logging.logger import LogLevel


struct LogSampler(Copyable):
    var rate_percent: Int
    var deterministic: Bool

    def __init__(out self, rate_percent: Int = 100, deterministic: Bool = True):
        self.rate_percent = rate_percent
        self.deterministic = deterministic

    def should_sample(self, level: LogLevel, message: String) -> Bool:
        if level.value >= 3:
            return True
        if self.rate_percent >= 100:
            return True
        if self.rate_percent <= 0:
            return False
        var basis = len(message)
        if not self.deterministic:
            basis += level.value * 13
        return (basis % 100) < self.rate_percent

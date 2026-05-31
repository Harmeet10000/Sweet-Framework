# In-memory async log queue foundation.

struct LogQueue(Copyable):
    var capacity: Int
    var drop_on_full: Bool
    var entries: List[String]
    var dropped_count: Int

    def __init__(out self, capacity: Int = 1024, drop_on_full: Bool = True):
        self.capacity = capacity
        self.drop_on_full = drop_on_full
        self.entries = List[String]()
        self.dropped_count = 0

    def enqueue(mut self, entry: String) -> Bool:
        if len(self.entries) >= self.capacity:
            if self.drop_on_full:
                self.dropped_count += 1
                return False
            _ = self.entries.pop(0)
        self.entries.append(entry)
        return True

    def dequeue(mut self) -> Optional[String]:
        if len(self.entries) == 0:
            return None
        return self.entries.pop(0)

    def is_empty(self) -> Bool:
        return len(self.entries) == 0

    def size(self) -> Int:
        return len(self.entries)

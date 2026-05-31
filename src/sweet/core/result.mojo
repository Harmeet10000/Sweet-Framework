from sweet.core.error import Error


struct Result[T, E]:
    var _is_ok: Bool
    var _value: Optional[T]
    var _error: Optional[E]

    def __init__(out self, is_ok: Bool, value: Optional[T], error: Optional[E]):
        self._is_ok = is_ok
        self._value = value
        self._error = error

    def is_ok(self) -> Bool:
        return self._is_ok

    def unwrap(self) raises -> T:
        if self._value is None:
            raise Error("Tried to unwrap an Err result")
        return self._value.value()

    def unwrap_err(self) raises -> E:
        if self._error is None:
            raise Error("Tried to unwrap_err an Ok result")
        return self._error.value()


def Ok[T, E](value: T) -> Result[T, E]:
    return Result[T, E](True, value, None)


def Err[T, E](error: E) -> Result[T, E]:
    return Result[T, E](False, None, error)

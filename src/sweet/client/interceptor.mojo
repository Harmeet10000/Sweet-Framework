# Request and response interceptor foundations.

from sweet.core.error import Error


struct RequestInterceptor(Copyable):
    var name: String
    var required_header: String
    var abort_message: String
    var headers_to_add: Dict[String, String]
    var metadata_to_add: Dict[String, String]

    def __init__(out self, name: String):
        self.name = name
        self.required_header = ""
        self.abort_message = ""
        self.headers_to_add = Dict[String, String]()
        self.metadata_to_add = Dict[String, String]()

    def require_header(mut self, header_name: String, abort_message: String):
        self.required_header = header_name
        self.abort_message = abort_message

    def add_header(mut self, key: String, value: String):
        self.headers_to_add[key] = value

    def add_metadata(mut self, key: String, value: String):
        self.metadata_to_add[key] = value


struct ResponseInterceptor(Copyable):
    var name: String
    var metadata_to_add: Dict[String, String]
    var force_error_status_at_or_above: Int

    def __init__(out self, name: String):
        self.name = name
        self.metadata_to_add = Dict[String, String]()
        self.force_error_status_at_or_above = 0

    def add_metadata(mut self, key: String, value: String):
        self.metadata_to_add[key] = value

    def fail_at_or_above(mut self, status: Int):
        self.force_error_status_at_or_above = status


def ensure_required_header(headers: Dict[String, String], name: String, abort_message: String) raises:
    if name == "":
        return
    if name not in headers:
        raise Error(abort_message)

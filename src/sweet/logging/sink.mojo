# Structured logging sinks.

from sweet.core.error import Error
from std.ffi import external_call
from std.memory import UnsafePointer, alloc
from std.pathlib import Path


struct UdpDestination(Copyable):
    var host: String
    var port: Int

    def __init__(out self, host: String, port: Int):
        self.host = host
        self.port = port


struct SockAddrIn:
    var sin_family: UInt16
    var sin_port: UInt16
    var sin_addr: UInt32
    var sin_zero_0: UInt8
    var sin_zero_1: UInt8
    var sin_zero_2: UInt8
    var sin_zero_3: UInt8
    var sin_zero_4: UInt8
    var sin_zero_5: UInt8
    var sin_zero_6: UInt8
    var sin_zero_7: UInt8


def send_udp_payload(host: String, port: Int, payload: String) raises:
    var AF_INET = 2
    var SOCK_DGRAM = 2
    var SOCKADDR_IN_LEN = 16

    var socket_fd = external_call["socket", Int](AF_INET, SOCK_DGRAM, 0)
    if socket_fd < 0:
        raise Error("failed to create udp socket")

    var resolved_host = host
    if host == "localhost":
        resolved_host = "127.0.0.1"

    var host_cstr = String(resolved_host + "\0")
    var addr = alloc[SockAddrIn](1)
    addr[].sin_family = UInt16(AF_INET)
    addr[].sin_port = external_call["htons", UInt16](UInt16(port))
    addr[].sin_addr = external_call["inet_addr", UInt32](host_cstr.unsafe_ptr())
    if addr[].sin_addr == UInt32(0xFFFFFFFF):
        addr.free()
        raise Error("failed to parse udp host")
    addr[].sin_zero_0 = 0
    addr[].sin_zero_1 = 0
    addr[].sin_zero_2 = 0
    addr[].sin_zero_3 = 0
    addr[].sin_zero_4 = 0
    addr[].sin_zero_5 = 0
    addr[].sin_zero_6 = 0
    addr[].sin_zero_7 = 0

    var sent = external_call["sendto", Int](socket_fd, payload.unsafe_ptr(), len(payload), 0, addr, SOCKADDR_IN_LEN)
    addr.free()

    if sent < 0 or sent != len(payload):
        raise Error("failed to send udp payload")


def parse_udp_destination(destination: String) -> Optional[UdpDestination]:
    if "://" not in destination:
        return None

    var url_parts = destination.split("://")
    if len(url_parts) != 2:
        return None
    if String(url_parts[0]) != "udp":
        return None

    var remainder = String(url_parts[1])
    if len(remainder) == 0 or ":" not in remainder:
        return None

    var host_port = remainder.split(":")
    if len(host_port) != 2:
        return None

    var host = String(host_port[0])
    var port_text = String(host_port[1])
    if len(host) == 0 or len(port_text) == 0:
        return None

    try:
        var port = Int(port_text)
        if port <= 0:
            return None
        return UdpDestination(host, port)
    except:
        return None

struct LogSink(Copyable):
    var name: String
    var entries: List[String]
    var error_count: Int
    var sink_type: String
    var destination: String
    var is_available: Bool
    var rotation_enabled: Bool
    var max_file_size_bytes: Int

    def __init__(out self, name: String, sink_type: String = "memory", destination: String = ""):
        self.name = name
        self.entries = List[String]()
        self.error_count = 0
        self.sink_type = sink_type
        self.destination = destination
        self.is_available = True
        self.rotation_enabled = False
        self.max_file_size_bytes = 0

    def write(mut self, entry: String):
        if not self.is_available:
            self.error_count += 1
            return
        if self.sink_type == "network" and len(self.destination) > 0:
            var parsed = parse_udp_destination(self.destination)
            if parsed is None:
                self.error_count += 1
                return
            try:
                send_udp_payload(parsed.value().host, parsed.value().port, entry)
            except:
                self.error_count += 1
                return
        if self.sink_type == "file" and len(self.destination) > 0:
            try:
                var path = Path(self.destination)
                var existing = ""
                if path.exists():
                    existing = path.read_text()
                if self.rotation_enabled and self.max_file_size_bytes > 0 and len(existing) + len(entry) + 1 > self.max_file_size_bytes:
                    existing = ""
                path.write_text(existing + entry + "\n")
            except:
                self.error_count += 1
                return
        self.entries.append(entry)

    def flush(self):
        pass

    def fail(mut self):
        self.is_available = False

    def recover(mut self):
        self.is_available = True

    def enable_rotation(mut self, max_file_size_bytes: Int):
        self.rotation_enabled = True
        self.max_file_size_bytes = max_file_size_bytes

    def count(self) -> Int:
        return len(self.entries)

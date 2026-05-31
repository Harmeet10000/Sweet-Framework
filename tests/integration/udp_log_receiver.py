import socket
from pathlib import Path


def main() -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("127.0.0.1", 15140))
    data, _ = sock.recvfrom(65535)
    Path("/tmp/sweet-udp.log").write_text(data.decode("utf-8"))
    sock.close()


if __name__ == "__main__":
    main()

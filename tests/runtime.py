"""Exercise actual kernel restrictions and local TCP scanning in every profile."""
import errno
import fcntl
import http.server
import os
from pathlib import Path
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import xml.etree.ElementTree as ET

profile = sys.argv[1]
status = dict(line.split(":", 1) for line in Path("/proc/self/status").read_text().splitlines() if ":" in line)
expected_caps = {"default": 0, "raw": (1 << 1) | (1 << 13), "vpn": (1 << 1) | (1 << 13) | (1 << 12)}[profile]
assert int(status["CapEff"].strip(), 16) == expected_caps, status["CapEff"]
assert int(status["CapBnd"].strip(), 16) == expected_caps, status["CapBnd"]
assert status["NoNewPrivs"].strip() == "1", "Privilege escalation is permitted"
assert (os.getuid() != 0) == (profile == "default"), "Unexpected container user"
assert not Path("/var/run/docker.sock").exists(), "Docker socket is exposed"

for directory in ["/etc", "/labs", "/scripts", "/wordlists"]:
    probe = Path(directory) / ".secbox-ci-probe"
    try:
        probe.write_text("must fail")
    except OSError as error:
        assert error.errno == errno.EROFS, (directory, error)
    else:
        probe.unlink()
        raise AssertionError(f"{directory} is writable")

for directory in ["/work", "/tmp", os.environ["HOME"]]:
    probe = Path(directory) / ".secbox-ci-probe"
    probe.write_text("writable")
    probe.unlink()

try:
    raw_socket = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
except PermissionError:
    assert profile == "default", "Raw mode has no effective NET_RAW capability"
else:
    raw_socket.close()
    assert profile != "default", "Default mode can open raw sockets"

if profile == "vpn":
    assert Path("/vpn/client.ovpn").is_file()
    tun = os.open("/dev/net/tun", os.O_RDWR)
    try:
        # Creating a TUN interface exercises NET_ADMIN inside this container.
        fcntl.ioctl(tun, 0x400454CA, struct.pack("16sH", b"secboxtest0", 0x0001 | 0x1000))
    finally:
        os.close(tun)

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200 if self.path in ["/", "/probe"] else 404)
        self.end_headers()
        self.wfile.write(b"secbox-local-test")

    def log_message(self, *args):
        pass

with http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler) as server:
    threading.Thread(target=server.serve_forever, daemon=True).start()
    port = str(server.server_address[1])
    output = subprocess.run(
        ["nmap", "-sT", "-Pn", "-p", port, "127.0.0.1", "-oX", "-"],
        check=True, capture_output=True, text=True, timeout=20,
    ).stdout
    assert ET.fromstring(output).find(".//port/state").get("state") == "open"
    output = subprocess.run(
        ["httpx", "-u", f"http://127.0.0.1:{port}", "-silent", "-duc"],
        check=True, capture_output=True, text=True, timeout=30,
    ).stdout
    assert f"127.0.0.1:{port}" in output, output
    # Exercise updated shared Go dependencies through real HTTP tool behaviour.
    with tempfile.TemporaryDirectory() as directory:
        wordlist = Path(directory) / "words.txt"
        wordlist.write_text("probe\nmissing\n")
        report = Path(directory) / "ffuf.json"
        subprocess.run(
            ["ffuf", "-u", f"http://127.0.0.1:{port}/FUZZ", "-w", str(wordlist),
             "-mc", "200", "-noninteractive", "-s", "-of", "json", "-o", str(report)],
            check=True, capture_output=True, text=True, timeout=30,
        )
        import json
        matches = json.loads(report.read_text())["results"]
        assert len(matches) == 1 and matches[0]["url"].endswith("/probe"), matches
        output = subprocess.run(
            ["gobuster", "dir", "-u", f"http://127.0.0.1:{port}", "-w", str(wordlist),
             "--no-progress", "--quiet"],
            check=True, capture_output=True, text=True, timeout=30,
        ).stdout
        assert "/probe" in output and "/missing" not in output, output
    server.shutdown()

print(f"{profile}: capabilities, mounts, user and local Nmap/httpx/ffuf/Gobuster checks passed")

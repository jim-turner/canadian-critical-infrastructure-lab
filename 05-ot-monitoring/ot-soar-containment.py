#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import ipaddress

PORT = 9090
PROTECTED_IPS = {"10.0.30.10", "10.0.30.20", "127.0.0.1"}

class ContainmentHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            return

        src_ip = data.get("src", "").strip()
        note = data.get("note", "")

        try:
            ip_obj = ipaddress.ip_address(src_ip)
        except ValueError:
            self.send_response(400)
            self.end_headers()
            return

        if str(ip_obj) in PROTECTED_IPS:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"Protected infrastructure IP ignored\n")
            return

        if self.path == "/isolate":
            check = subprocess.run(
                ["iptables", "-C", "INPUT", "-s", str(ip_obj), "-p", "tcp", "--dport", "502", "-j", "DROP"],
                capture_output=True
            )
            if check.returncode != 0:
                subprocess.run(
                    ["iptables", "-I", "INPUT", "1", "-s", str(ip_obj), "-p", "tcp", "--dport", "502", "-j", "DROP"],
                    check=False
                )
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"Isolated {ip_obj} due to {note}\n".encode())
        elif self.path == "/release":
            subprocess.run(
                ["iptables", "-D", "INPUT", "-s", str(ip_obj), "-p", "tcp", "--dport", "502", "-j", "DROP"],
                check=False
            )
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"Released {ip_obj}\n".encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("10.0.30.10", PORT), ContainmentHandler) as httpd:
    httpd.serve_forever()

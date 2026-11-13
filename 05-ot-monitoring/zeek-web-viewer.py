#!/usr/bin/env python3
import http.server
import socketserver
import os
import html

PORT = 8085
LOG_DIR = "/opt/zeek/logs/current"

class ZeekHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        log_file = "notice.log" if self.path == "/notices" else "modbus.log"
        filepath = os.path.join(LOG_DIR, log_file)

        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()

        rows_html = ""
        headers_html = ""
        if os.path.exists(filepath):
            with open(filepath, "r", errors="replace") as f:
                lines = f.readlines()
            for line in lines:
                if line.startswith("#fields"):
                    cols = line.strip().split("\t")[1:]
                    headers_html = "".join(f"<th>{html.escape(c)}</th>" for c in cols)
            data_lines = [l for l in lines if not l.startswith("#")][-50:]
            for line in reversed(data_lines):
                cols = line.strip().split("\t")
                row = "".join(f"<td>{html.escape(c)}</td>" for c in cols)
                row_class = "write" if "WRITE" in line else ""
                rows_html += f"<tr class=\"{row_class}\">{row}</tr>\n"
        else:
            rows_html = f"<tr><td colspan=\"10\">Waiting for {log_file} events...</td></tr>"

        page = f"""<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="3">
  <title>Zeek OT Sensor - {log_file}</title>
  <style>
    body {{ font-family: monospace; background: #111827; color: #e5e7eb; margin: 20px; }}
    h2 {{ color: #38bdf8; }}
    a {{ color: #38bdf8; margin-right: 15px; text-decoration: none; font-weight: bold; }}
    table {{ border-collapse: collapse; width: 100%; margin-top: 15px; font-size: 13px; }}
    th, td {{ border: 1px solid #374151; padding: 6px 10px; text-align: left; }}
    th {{ background: #1f2937; color: #93c5fd; }}
    tr:nth-child(even) {{ background: #1a2234; }}
    tr.write {{ background: #7f1d1d; color: #fecaca; font-weight: bold; }}
  </style>
</head>
<body>
  <h2>Zeek OT Sensor (10.0.30.40) — {log_file} (Auto-refreshes every 3s)</h2>
  <div>
    <a href="/">[modbus.log]</a>
    <a href="/notices">[notice.log (Alerts)]</a>
  </div>
  <table>
    <thead><tr>{headers_html}</tr></thead>
    <tbody>{rows_html}</tbody>
  </table>
</body>
</html>"""
        self.wfile.write(page.encode("utf-8"))

    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(("0.0.0.0", PORT), ZeekHandler) as httpd:
    httpd.serve_forever()

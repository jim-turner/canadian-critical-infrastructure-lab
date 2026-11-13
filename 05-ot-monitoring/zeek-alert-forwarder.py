#!/usr/bin/env python3
import time
import os
import json
import urllib.request

LOG_PATH = "/opt/zeek/logs/current/notice.log"
WEBHOOK_URL = "http://10.0.30.20:1880/zeek-alert"

def follow(path):
    while not os.path.exists(path):
        time.sleep(1)
    f = open(path, "r", errors="replace")
    f.seek(0, os.SEEK_END)
    current_inode = os.fstat(f.fileno()).st_ino
    while True:
        line = f.readline()
        if not line:
            time.sleep(0.5)
            try:
                if os.stat(path).st_ino != current_inode:
                    f.close()
                    f = open(path, "r", errors="replace")
                    current_inode = os.fstat(f.fileno()).st_ino
            except FileNotFoundError:
                pass
            continue
        yield line

for line in follow(LOG_PATH):
    if line.startswith("#") or not line.strip():
        continue
    cols = line.strip().split("\t")
    if len(cols) >= 12:
        payload = {
            "ts": cols[0],
            "src": cols[2],
            "dst": cols[4],
            "note": cols[10],
            "msg": cols[11]
        }
        req = urllib.request.Request(
            WEBHOOK_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        try:
            urllib.request.urlopen(req, timeout=2)
        except Exception:
            pass

#!/usr/bin/env python3
import time
import os
import json
import urllib.request

LOG_PATH = "/opt/zeek/logs/current/notice.log"
HMI_WEBHOOK_URL = "http://10.0.30.20:1880/zeek-alert"
SOAR_ISOLATE_URL = "http://10.0.30.10:9090/isolate"

CRITICAL_NOTES = {
    "OT_Modbus_IDS::Safety_Interlock_Tampering",
    "OT_Modbus_IDS::Sensor_Register_Spoofing",
    "OT_Modbus_IDS::Rapid_Modbus_Write_Burst"
}

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

def post_json(url, payload):
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        urllib.request.urlopen(req, timeout=2)
    except Exception:
        pass

for line in follow(LOG_PATH):
    if line.startswith("#") or not line.strip():
        continue
    cols = line.strip().split("\t")
    if len(cols) >= 12:
        note = cols[10]
        src = cols[2]
        payload = {
            "ts": cols[0],
            "src": src,
            "dst": cols[4],
            "note": note,
            "msg": cols[11]
        }
        if note in CRITICAL_NOTES:
            post_json(SOAR_ISOLATE_URL, payload)
            payload["msg"] = f"[AUTO-CONTAINED: {src} BLOCKED ON TCP/502] " + payload["msg"]
        post_json(HMI_WEBHOOK_URL, payload)

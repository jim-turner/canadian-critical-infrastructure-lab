# OT/ICS Incident Response Report — Unauthorized Modbus TCP Write & SOAR Containment

**Incident ID:** `IR-CMWTF01-2026-001`  
**Affected System:** Canadian Municipal Water Treatment Facility (`CMWTF-01`) — Level 1 PLC (`10.0.30.10`)  
**Detection & Response Engine:** `zeek-ids-01` (Modbus DPI + Automated `iptables` SOAR)  
**Framework Alignment:** NIST SP 800-61 Rev. 2 & MITRE ATT&CK for ICS

---

## 1. Executive Summary

During an active purple-team validation exercise on `CMWTF-01`, a rogue workstation node outside the allowlisted SCADA/HMI subnet (`!= 10.0.30.20`) initiated unauthorized Modbus TCP (`TCP/502`) write commands (`FC 05` Force Single Coil) targeting the municipal distribution pump (`%QX0.3`) and high-level safety interlock (`%QX0.0`).

* **Physical Impact Prevented:** Zero disruption to municipal water distribution (`80 L/min` maintained) and zero safety interlock bypass.
* **Mean Time to Detect (MTTD):** `< 150 ms` via Zeek `modbus` protocol analyzer.
* **Mean Time to Contain (MTTC):** `< 450 ms` via automated `iptables` host isolation on `openplc-rt-01` (`LXC 102`) and real-time webhook alert delivery to the Level 2 Node-RED HMI (`10.0.30.20:1880/zeek-alert`).

---

## 2. Incident Timeline & MITRE ATT&CK for ICS Correlation

| Timestamp (UTC) | Phase | Telemetry / Event Source | MITRE ATT&CK for ICS | Description & Technical Artifacts |
| :--- | :--- | :--- | :--- | :--- |
| `T+00.000s` | Reconnaissance | Zeek `conn.log` / `modbus.log` | **T0840** — Network Connection Enumeration / **T0801** — Monitor Process State | Rogue source IP opens `TCP/502` session to `10.0.30.10` and issues `FC 03` (Read Holding Registers `0–4`) to enumerate tank levels and flow rate. |
| `T+01.120s` | Execution / Impair Process | Zeek `modbus.log` (`FC 05`) | **T0855** — Unauthorized Command Message / **T0813** — Denial of Control | Rogue host transmits `FC 05` (`0x0000` OFF) to Coil `3` (`%QX0.3` `dist_pump_cmd`) attempting to halt municipal outflow. |
| `T+01.185s` | Impact / Tampering | Zeek `modbus.log` (`FC 05`) | **T0878** — Alarm Suppression / **T0836** — Modify Parameter | Rogue host transmits `FC 05` (`0x0000` OFF) to Coil `0` (`%QX0.0` `high_level_alarm`) attempting to mask overflow state. |
| `T+01.240s` | Detection | Zeek `notice.log` | `CMWTF01::Unauthorized_Modbus_Write` | Zeek policy evaluates `src_ip != 10.0.30.20` with write function code `FC 05` and raises critical notice. |
| `T+01.410s` | Containment (SOAR) | `openplc-rt-01` `iptables` & Node-RED HMI | Automated Active Defense | SOAR hook injects `iptables -I INPUT -s <rogue_ip> -j DROP` on `10.0.30.10` and posts JSON alert banner to `http://10.0.30.20:1880/zeek-alert`. |

---

## 3. Forensic Evidence & Protocol Analysis

### Zeek modbus.log & notice.log Indicators
```text
# Zeek modbus.log excerpt (sanitized)
ts          uid                 id.orig_h     id.resp_h   id.resp_p  func                exception
1731513001  CHhAvVGS1DHFjwGM9   10.0.1.50     10.0.30.10  502        FORCE_SINGLE_COIL   -

# Zeek notice.log excerpt
note                                  msg                                                         sub
CMWTF01::Unauthorized_Modbus_Write    Unauthorized Modbus FC 05 write from 10.0.1.50 to PLC       MITRE_ICS:T0855,T0878
```

### PLC Safety Instrumented System (SIS) Resilience
1. **Coil 0 (%QX0.0) Protection:** water_treatment-v5.st continuously evaluates high_level_alarm on every 100 ms scan cycle, overriding external coil manipulation.
2. **HMI Operator Visibility:** Node-RED Dashboard 2.0 transitioned to a critical alert banner displaying the rogue IP, targeted coil, and MITRE ATT&CK technique IDs.

## 4. Eradication, Recovery & Lessons Learned

| Phase | Action Taken | Verification Criteria |
| :--- | :--- | :--- |
| **Containment** | Automated iptables -I INPUT -s <rogue_ip> -j DROP on openplc-rt-01 (LXC 102). | Rogue packets dropped (0 responses); 10.0.30.20 HMI polling unaffected. |
| **Eradication** | Terminated rogue Modbus client and audited ss -tnp on TCP/502. | Only active TCP/502 session is 10.0.30.20. |
| **Recovery** | Verified steady-state telemetry across %QW0–%QW4. | 1.2 NTU turbidity, 1.85 ppm chlorine, 80 L/min outflow. |
| **Lessons Learned** | Enforce default-deny TCP/502 firewalling allowlisted solely to 10.0.30.20. | Verified via iptables -L INPUT -n -v on LXC 102. |

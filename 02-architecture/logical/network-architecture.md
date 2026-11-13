# Logical Network Architecture & IP Allocation — CMWTF-01

## 1. Active Laboratory Segmentation

This architecture preserves the validated operational subnets while isolating management, OT control, and security monitoring planes.

| Segment / Zone | Subnet | Purdue Level | Purpose & Security Boundary |
| :--- | :--- | :--- | :--- |
| Management & SOC Plane | 10.0.1.0/24 | Level 4 / Level 3.5 | Proxmox hypervisor management (10.0.1.32), engineering workstation, and Wazuh SIEM |
| OT / SCADA Control Plane | 10.0.30.0/24 | Levels 1–2 | Isolated industrial control subnet for OpenPLC (10.0.30.10) and Node-RED HMI (10.0.30.20) |
| Passive Inspection Bridge | SPAN / Virtual Tap | Level 3.5 (DMZ) | Out-of-band packet mirroring to Zeek OT IDS + SOAR engine |

---

## 2. Active & Planned Host Allocation

| Device / Workload | Container / VM | Subnet / IP | Status |
| :--- | :--- | :--- | :--- |
| Proxmox Hypervisor (pve2) | Host | 10.0.1.32 | Active |
| OpenPLC Runtime (water_treatment-v5.st) | LXC 102 | 10.0.30.10 | Active (Modbus TCP/502) |
| Node-RED Dashboard 2.0 HMI | LXC 105 | 10.0.30.20 | Active (Port 1880 + /zeek-alert) |
| Zeek OT IDS + SOAR Engine | Sensor | SPAN / Bridge | Active (Modbus DPI + iptables SOAR) |
| Wazuh SIEM Server | VM201 (8 GB RAM) | 10.0.1.40 | Planned (Phase 6 Endpoint & Log Monitoring) |

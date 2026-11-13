# Security Zones & Inter-VLAN Communication Matrix — CMWTF-01

## 1. Security Zone Trust Boundaries

Default policy: **DENY ALL** inter-VLAN traffic unless explicitly permitted below.

| Zone | VLAN | Trust Level | Functional Responsibility |
| :--- | :--- | :--- | :--- |
| Management | VLAN 10 (10.60.10.0/24) | High | Proxmox hypervisor & firewall administration |
| Enterprise IT | VLAN 20 (10.60.20.0/24) | Separate | Corporate IT systems (no direct OT access) |
| OT DMZ | VLAN 30 (10.60.30.0/24) | Restricted | Controlled data exchange & jump host mediation |
| OT Operations | VLAN 40 (10.60.40.0/24) | Restricted | Site operations & OT historian aggregation |
| SCADA / HMI | VLAN 50 (10.60.50.0/24) | Restricted | Supervisory control, Node-RED & operator HMI |
| PLC Control | VLAN 60 (10.60.60.0/24) | Highly Restricted | OpenPLC runtime & cyber-physical control loop |
| Security SOC | VLAN 70 (10.60.70.0/24) | Restricted | Wazuh SIEM, Zeek passive NSM & Grafana |

---

## 2. Explicit Firewall & Conduit Ruleset

| Rule ID | Source Zone / IP | Destination Zone / IP | Protocol / Port | Purpose | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- |
| FW-01 | Management (10.60.10.20) | Proxmox Hosts (10.60.10.11–.12) | TCP/8006, TCP/22 | Hypervisor administration | **Permit** |
| FW-02 | SCADA / Node-RED (10.60.50.10–.20) | OpenPLC (10.60.60.10) | TCP/502 (Modbus) | Authorized supervisory polling & control | **Permit** |
| FW-03 | OT Historian (10.60.40.10) | OT DMZ (10.60.30.0/24) | TCP/443 / Specific API | Controlled telemetry replication | **Permit** |
| FW-04 | OT / IT Subnets | Wazuh Server (10.60.70.10) | TCP/1514, TCP/1515 | Endpoint agent telemetry & enrollment | **Permit** |
| FW-05 | SPAN / Mirror Port | Zeek Sensor (10.60.70.20) | Passive Tap (All) | Out-of-band NSM & Modbus DPI | **Observe** |
| FW-06 | Enterprise IT (VLAN 20) | OT Control / SCADA (VLAN 50–60) | Any | Direct corporate-to-OT traversal | **Deny** |
| FW-07 | Wireless (VLAN 80) | All OT & Management VLANs | Any | Guest/wireless lateral access | **Deny** |
| FW-08 | Internet / WAN | All Internal VLANs (10–90) | Any | External unsolicited inbound traffic | **Deny** |

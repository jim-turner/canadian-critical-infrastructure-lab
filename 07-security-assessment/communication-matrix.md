# Inter-Zone Communication Requirements Matrix — CMWTF-01

Default policy: **DENY ALL** cross-segment traffic unless explicitly permitted below.

| Rule ID | Source | Destination | Protocol / Port | Purpose | Decision |
| :--- | :--- | :--- | :--- | :--- | :--- |
| FW-01 | Engineering Workstation | pve2 (10.0.1.32) | TCP/8006, TCP/22 | Hypervisor & LXC administration | **Permit** |
| FW-02 | Node-RED HMI (10.0.30.20) | OpenPLC (10.0.30.10) | TCP/502 (Modbus) | Authorized supervisory polling & coil control | **Permit** |
| FW-03 | Zeek SOAR Engine | Node-RED HMI (10.0.30.20) | TCP/1880 (/zeek-alert) | Real-time IDS alert webhook delivery | **Permit** |
| FW-04 | OT SPAN / Bridge | Zeek IDS Sensor | Passive Mirror (All) | Out-of-band Modbus TCP deep packet inspection | **Observe** |
| FW-05 | OT Containers (10.0.30.10/.20) | Wazuh Server (10.0.1.40) | TCP/1514, TCP/1515 | Linux auth, syslog & File Integrity Monitoring | **Permit** |
| FW-06 | Non-HMI Hosts (!= 10.0.30.20) | OpenPLC (10.0.30.10) | TCP/502 (FC 05/06/15/16) | Unauthorized PLC write attempts | **Deny + SOAR Drop** |

# Proxmox VE Host Network & Guest Inventory (PVE-2 Ground Truth)

## Overview
This document records the exact Layer 2/3 bridge topology and guest container/VM configurations for hypervisor node **PVE-2** (`10.0.1.32`), extracted directly from the Proxmox CLI (`pveversion`, `/etc/network/interfaces`, `qm list`, `pct list`).

---

## 1. PVE-2 Host Network Configuration

* **Proxmox Version:** `pve-manager/9.2.26` (Kernel `7.0.14-28-pve`)
* **Physical Management Uplink:** `nic0` -> `vmbr0` (`10.0.1.32/24`, Gateway: `10.0.1.1`)

| Interface | Type | Bridge Ports | VLAN Aware | State | Purpose |
|---|---|---|---|---|---|
| `nic0` | Physical NIC | — | NO | Manual | Primary trunk link to UniFi Switch Port 0/45 |
| `vmbr0` | Linux Bridge | `nic0` | YES | Static (`10.0.1.32`) | Main VLAN-aware bridge carrying untagged Mgmt (VLAN 1) and Tagged VLANs 10–70 |
| `vmbr1` | Linux Bridge | `none` | NO | Manual | Isolated internal host-only network bridge |
| `vmbr2` | Linux Bridge | `none` | NO | Manual | Secondary internal host-only network bridge |

---

## 2. PVE-2 Guest Virtual Machine & Container Inventory

| VM/LXC ID | Guest Type | Hostname / Name | Cores | RAM | Root Disk | MAC Address | Current Interface Config |
|---|---|---|---|---|---|---|---|
| `102` | LXC Container | `openplc-rt-01` | 1 | 1024 MB | 8 GB | `BC:24:11:01:D1:6B` | `eth0`, `vmbr0`, `192.168.10.150/24` |
| `104` | LXC Container | `zeek-sensor-01` | 2 | 1024 MB | 8 GB | `BC:24:11:7E:20:DA` | `eth0`, `vmbr0`, `192.168.10.51/24` |
| `105` | LXC Container | `ignition-scada-01` | 2 | 2048 MB | 10 GB | `BC:24:11:3B:42:CB` | `eth0`, `vmbr0`, `192.168.10.51/24` |
| `108` | QEMU VM | `GRFICSv3` | 4 | 4096 MB | 70 GB | `BC:24:11:E7:13:59` | `net0`, `vmbr0`, Tag `99` |
| `9000` | QEMU VM | `ubuntu-server-template` | 2 | 2048 MB | 20 GB | `BC:24:11:78:56:14` | Template Base |

---

## 3. Required Re-alignment for CMWTF-01 Phase 3 (VLAN 30 Integration)

To integrate these guests into **VLAN 30 (Industrial_OT)** on subnet `10.0.30.0/24` (Gateway: `10.0.30.1`), the following updates must be applied via `pct set` / `qm set`:

1. **LXC 102 (`openplc-rt-01`):** Set IP to `10.0.30.10/24`, Gateway `10.0.30.1`, Tag `30`.
2. **LXC 105 (`ignition-scada-01`):** Resolve IP conflict with 104; set IP to `10.0.30.20/24`, Gateway `10.0.30.1`, Tag `30`.
3. **VM 108 (`GRFICSv3`):** Update `net0` tag from `99` to `30`, assign IP `10.0.30.30/24`.
4. **LXC 104 (`zeek-sensor-01`):** Set IP to `10.0.30.40/24`, Gateway `10.0.30.1`, Tag `30` (or set up for bridge mirroring).

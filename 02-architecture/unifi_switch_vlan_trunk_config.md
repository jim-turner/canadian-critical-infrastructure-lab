# UniFi US-48-750W VLAN & Trunk Port Configuration

## Overview
This document records the VLAN database additions and custom port profile setup for the UniFi US-48-750W switch (`SW-1-US`). The goal of this configuration is to trunk tagged VLANs to the EdgeRouter Pro 8 uplink and Proxmox hypervisor hosts while preserving untagged management access on VLAN 1.

---

## 1. VLAN Database Architecture

| VLAN ID | Name | Network Description | Type |
|---|---|---|---|
| **1** | Default / Management | Subnet `10.0.1.0/24` (Untagged Management Traffic) | Native |
| **10** | Management_Tagged | Tagged Management Subinterface | Tagged |
| **20** | VLAN0020 | Pre-existing Lab VLAN | Tagged |
| **30** | Industrial_OT | Operational Technology / ICS Simulation | Tagged |
| **40** | Security_SOC | Security Operations Center / Monitoring | Tagged |
| **50** | VLAN50 | Lab Segment 50 | Tagged |
| **60** | VLAN60 | Lab Segment 60 | Tagged |
| **70** | VLAN70 | Lab Segment 70 | Tagged |

---

## 2. Port Profile Setup (`Lab_Trunk`)

Created in **UniFi Controller > Settings > Profiles > Switch Ports**:

* **Profile Name:** `Lab_Trunk`
* **Native Network:** `Default` (`10.0.1.0/24` / Untagged VLAN 1)
* **Tagged VLAN Management:** `Custom`
* **Tagged Networks Included:** `10`, `20`, `30`, `40`, `50`, `60`, `70`

---

## 3. Port Assignments

| Port | Description | Applied Profile | Native VLAN | Tagged VLANs |
|---|---|---|---|---|
| **0/15** | Uplink to EdgeRouter Pro 8 (`eth1`) | `Lab_Trunk` | 1 | 10, 20, 30, 40, 50, 60, 70 |
| **0/45** | Proxmox Host 2 (`PVE-2`) | `Lab_Trunk` | 1 | 10, 20, 30, 40, 50, 60, 70 |
| **0/47** | Proxmox Host 3 (`PVE-3`) | `Lab_Trunk` | 1 | 10, 20, 30, 40, 50, 60, 70 |

---

## 4. Verification & Validation Steps

1. **VLAN Database Verification:**
   * In UniFi Web UI: **Settings > Networks** shows all VLANs (10, 20, 30, 40, 50, 60, 70) defined under *Third-Party Gateway*.
   * Switch CLI check (`telnet 127.0.0.1` -> `enable` -> `show vlan`): Lists all VLAN IDs active in the switch engine.

2. **Interface Running Configuration Check:**
   * Executed `show running-config interface 0/15` on `SW-1-US`.
   * Verified output contains:
     * `vlan participation include 1,10,20,30,40,50,60,70`
     * `vlan tagging 10,20,30,40,50,60,70`

3. **Connectivity Verification:**
   * Untagged management traffic on `10.0.1.0/24` remained uninterrupted during and after controller provisioning.

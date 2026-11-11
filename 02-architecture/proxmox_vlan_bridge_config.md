# Proxmox VE Host Network Architecture (PVE-2 & PVE-3)

## Overview
This document details the Linux bridge setup and 802.1Q VLAN-aware configuration for Proxmox VE hosts PVE-2 and PVE-3.

## Bridge Layout
| Bridge Interface | VLAN Aware | Associated Ports | Role / Purpose |
|---|---|---|---|
| vmbr0 | YES | Physical Uplink (Port 0/45 or 0/47) | Main trunk bridge passing untagged Management (VLAN 1) and tagged VLANs (10, 20, 30, 40, 50, 60, 70) |
| vmbr1 | NO | Internal / Secondary NIC | Secondary network interface / isolated host network |
| vmbr2 | NO | Internal / Secondary NIC | Secondary network interface / isolated host network |

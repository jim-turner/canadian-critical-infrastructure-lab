# EdgeRouter Pro 8 VLAN Subinterface & L3 Routing Configuration

## Overview
This document details the Layer 3 VLAN subinterface configuration on the EdgeRouter Pro 8 (EdgeRouter-Pro-8-Port).

## 1. Physical & Virtual Interface Mapping
* Physical Trunk Interface: eth1
* Untagged Native Management Subnet: 10.0.1.1/24
* Uplink to WAN/Home Network: eth0 (192.168.1.250/24)

| Interface | VLAN ID | Description | Gateway IP / Subnet | State |
|---|---|---|---|---|
| eth1 | Native (1) | Management Untagged | 10.0.1.1/24 | u/u |
| eth1.10 | 10 | Management_Tagged | 10.0.10.1/24 | u/u |
| eth1.20 | 20 | VLAN0020 | 10.0.20.1/24 | u/u |
| eth1.30 | 30 | Industrial_OT | 10.0.30.1/24 | u/u |
| eth1.40 | 40 | Security_SOC | 10.0.40.1/24 | u/u |
| eth1.50 | 50 | VLAN50 | 10.0.50.1/24 | u/u |
| eth1.60 | 60 | VLAN60 | 10.0.60.1/24 | u/u |
| eth1.70 | 70 | VLAN70 | 10.0.70.1/24 | u/u |

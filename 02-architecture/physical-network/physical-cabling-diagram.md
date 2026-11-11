# Physical Cabling & Port Allocation (CMWTF-01)

## Switch & Router Connections (US-48-750W Switch SW-01)
- **Port 15:** EdgeRouter Pro 8 (`eth1`) — Core laboratory trunk uplink
- **Port 45:** Proxmox Host 01 (`pve-2`) — Industrial Host trunk
- **Port 47:** Proxmox Host 02 (`pve-3`) — Security & SOC Host trunk

## Connected Subnets & VLAN Trunking
All active ports (`15`, `45`, `47`) are configured as 802.1Q trunks passing lab VLANs (10, 30, 40, 50, 60, 70).

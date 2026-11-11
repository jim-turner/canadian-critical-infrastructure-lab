cat << 'EOF' > ~/projects/canadian-critical-infrastructure-lab/NODE-RED-DEPLOYMENT.md
# Node-RED SCADA Integration Platform Documentation

## 1. System Architecture & Network Layout

| Component | Target Identity | IP Address | Role / Function |
| :--- | :--- | :--- | :--- |
| **Workstation** | `jimturner` | `192.168.1.82/24` | Management host connected via Wi-Fi (`wlp0s20f3`) |
| **Lab Gateway Host** | Proxmox VE | `192.168.1.250` | Inter-VLAN router / bridge gateway for lab subnets |
| **SCADA Container** | LXC 105 (`ignition-scada-01`) | `10.0.30.20/24` | Headless Debian/Ubuntu LXC hosting Node-RED |
| **Node-RED UI** | Port `1880` | `10.0.30.20:1880` | Flow Editor (`/`) & Dashboard (`/ui`) |

---

## 2. Container Configuration (LXC 105)

### Network Listener (`/root/.node-red/settings.js`)
Node-RED is configured to listen across all IPv4 and IPv6 network interfaces using the dual-stack binding `"::"`:


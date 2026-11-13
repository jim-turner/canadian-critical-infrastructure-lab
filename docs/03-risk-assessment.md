# OT/ICS Cybersecurity Risk Assessment — CMWTF-01 Water Treatment Facility

**Assessment Frameworks:** IEC 62443-3-2 (Security Risk Assessment for System Design) & NIST SP 800-82 Rev. 3 (Guide to Operational Technology Security)  
**System Under Consideration (SuC):** Canadian Municipal Water Treatment Facility (`CMWTF-01`) — 4-Stage Filtration, Disinfection & Distribution Testbed

---

## 1. System Characterization & Criticality

`CMWTF-01` models a municipal potable water treatment train spanning Purdue Levels 0–4:
* **Level 0 (Physical Process):** Raw water intake (`%QW0`), rapid sand filtration (`%QW1`), free chlorine disinfection (`%QW2`), clearwell storage (`%QW3`), and municipal distribution (`%QW4`).
* **Level 1 (Basic Control & SIS):** `openplc-rt-01` (`10.0.30.10`, LXC 102) executing IEC 61131-3 logic (`water_treatment-v5.st`) with hardwired High-Level Overflow (`%QX0.0 >= 950 L`) and Low-Level Dry-Run (`%QX0.4 <= 15 L`) interlocks.
* **Level 2 (Supervisory Control):** `ignition-scada-01` (`10.0.30.20`, LXC 105) running Node-RED Dashboard 2.0 HMI over unauthenticated Modbus TCP (`TCP/502`).
* **Level 3.5 (Industrial DMZ):** `zeek-ids-01` performing Deep Packet Inspection (DPI) on `TCP/502` and executing automated `iptables` SOAR containment.

---

## 2. IEC 62443 Zone & Conduit Model

| Zone ID | Zone Name | Purdue Level | Assets | Target Security Level (SL-T) |
| :--- | :--- | :--- | :--- | :--- |
| **Z-01** | Field & Basic Control Zone | Levels 0–1 | `openplc-rt-01` (`10.0.30.10`), Virtual Field I/O | **SL-T 3** (Safety-Critical Physical Process) |
| **Z-02** | Supervisory & HMI Zone | Level 2 | `ignition-scada-01` (`10.0.30.20`) | **SL-T 2** (Operator Control & Telemetry) |
| **Z-03** | Industrial DMZ / SOC Zone | Level 3.5 | `zeek-ids-01`, SOAR Webhook & Firewall Engine | **SL-T 3** (Detection & Active Enforcement) |
| **Z-04** | Enterprise / Engineering Zone | Level 4 | Engineering Workstation (`pve2` mgmt / Git) | **SL-T 2** (IT / Engineering Administration) |

---

## 3. Threat Scenarios & Cyber-Physical Risk Register

Risk ratings follow NIST SP 800-82 / IEC 62443-3-2 methodology ($\text{Risk} = \text{Likelihood} \times \text{Consequence}$), prioritizing Health, Safety, and Environmental (HSE) impact.

| Risk ID | Threat Scenario & MITRE ATT&CK | Target Conduit / Asset | Inherent Risk | Existing & Compensating Controls | Residual Risk |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RSK-01** | **Unauthorized Actuator Manipulation (`T0855`):** Rogue host sends `FC 05` writes to force Intake Pump (`%QX0.1`) ON or Distribution Pump (`%QX0.3`) OFF, causing tank overflow or municipal loss of pressure. | `TCP/502` to `10.0.30.10` (`Z-01`) | **Critical** (L: High, C: Severe) | PLC High-Level (`>= 950 L`) & Low-Level (`<= 15 L`) hardwired SIS cutoffs; Zeek DPI detects non-HMI source IPs (`!= 10.0.30.20`) and triggers sub-second `iptables DROP`. | **Low** |
| **RSK-02** | **Safety Interlock & Alarm Suppression (`T0878` / `T0836`):** Adversary attempts to overwrite read-only safety coils (`%QX0.0`, `%QX0.4`) or alter process parameters to mask high turbidity (`> 5.0 NTU`) or unsafe chlorine residuals. | `TCP/502` Coils `0, 4` (`Z-01`) | **Critical** (L: Medium, C: Severe) | SIS interlock evaluation runs deterministically every `100 ms` PLC scan cycle, overriding external coil writes; Zeek flags coil `0`/`4` write attempts as high-severity tampering and quarantines host. | **Low** |
| **RSK-03** | **Modbus TCP Cleartext Sniffing & Replay (`T0801` / `T0840`):** Passive interception of `FC 03` telemetry or replay of captured `FC 05` command frames between Level 2 and Level 1. | Conduit `Z-02 ↔ Z-01` (`TCP/502`) | **High** (L: High, C: Moderate) | VLAN isolation (`10.0.30.0/24`) restricts Layer-2 adjacency; `iptables` allowlists `TCP/502` strictly to `10.0.30.20`; planned upgrade to Modbus/TCP Security (`TLS` / `TCP/802`). | **Medium** |
| **RSK-04** | **SCADA / HMI Compromise & Lateral Pivot (`T0859` / `T0886`):** Compromise of `ignition-scada-01` (`10.0.30.20`) allows an attacker to issue authorized-IP Modbus commands via Node-RED. | `TCP/1880` & SSH (`Z-02`) | **High** (L: Medium, C: High) | Hardwired PLC SIS interlocks remain immune to HMI commands; Zeek monitors behavioral anomalies (rapid actuator toggling); planned Node-RED RBAC & TLS enforcement. | **Medium** |
| **RSK-05** | **Denial of View / Loss of HMI Telemetry (`T0813` / `T0815`):** Flooding `TCP/502` or `TCP/1880` blinds operators during an active process upset. | `Z-01` & `Z-02` Network | **Medium** (L: Medium, C: Moderate) | Autonomous PLC control loop and safety interlocks maintain safe physical bounds without operator intervention; OpenPLC web diagnostic console provides out-of-band monitoring. | **Low** |

---

## 4. IEC 62443 Security Control Gap & Remediation Roadmap

| Priority | IEC 62443-3-3 Requirement | Gap Identified in Current Lab | Planned Engineering Remediation |
| :--- | :--- | :--- | :--- |
| **P1 (Immediate)** | **SR 3.1 / SR 4.1:** Communication Integrity & Confidentiality | Modbus TCP (`TCP/502`) lacks native authentication and encryption. | Deploy an encrypted TLS wrapper (`stunnel` / Modbus Security `TCP/802`) between `10.0.30.20` and `10.0.30.10`. |
| **P2 (Short-Term)** | **SR 1.1 / SR 2.1:** Human User Identification & RBAC | Node-RED Dashboard (`TCP/1880`) permits unauthenticated local subnet access. | Enable `adminAuth` and read-only vs. operator role separation in Node-RED `settings.js`. |
| **P3 (Medium-Term)** | **SR 6.1:** Audit Log Accessibility & Retention | Zeek IDS and Node-RED logs reside locally on containers. | Forward Zeek `modbus.log`, `notice.log`, and OpenPLC syslog to a centralized Level 3 SIEM/Historian. |

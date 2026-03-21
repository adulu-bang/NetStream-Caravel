# NetStream: Edge Network Processing SoC (Caravel-Based)

##  Overview

NetStream is a custom network packet-processing accelerator designed for edge IoT and industrial gateway applications, implemented within the Caravel SoC framework.

Edge devices today need to handle increasing volumes of network traffic while operating under tight latency, power, and cost constraints. Software-based packet processing on embedded processors often becomes a bottleneck, limiting real-time responsiveness and scalability in applications such as industrial monitoring, secure edge gateways, and smart infrastructure.

NetStream has been designed to addresses this challenge by introducing a dedicated hardware offload engine that accelerates packet inspection, classification, and action handling. By moving these tasks from software into hardware, the system achieves lower latency, higher throughput, and reduced CPU load under low-power constraints for edge devices.

The design is integrated with the Caravel management SoC, allowing programmable control and system-level integration. NetStream is intended to function as part of a complete edge networking system, interfacing with external Ethernet MAC and PHY components on a PCB.

---

##  Problem Statement

Edge devices and industrial gateways increasingly require:

- Real-time packet filtering and routing
- Low-latency decision making
- Energy-efficient networking
- On-device telemetry and monitoring

Software-based solutions are often too slow or power-hungry for constrained environments.

---

##  Proposed Solution

NetStream introduces a hardware packet-processing pipeline integrated into the Caravel user area, enabling:

- Line-rate packet parsing
- Configurable filtering rules
- Protocol-aware inspection
- Telemetry extraction (flow stats, counters)

The design is controlled via the Caravel RISC-V management core using the Wishbone interface.

---

## System Architecture

### On-Chip Components:
- Packet Parser Engine
- Rule Matching Engine (TCAM-like logic or simplified matcher)
- Flow Counter Unit
- Control Interface (Wishbone slave)

### Off-Chip Components (PCBA):
- Ethernet PHY (RMII/MII interface)
- Power management
- Optional microcontroller for system integration

### Firmware:
- Rule configuration API
- Monitoring interface
- Debug utilities

---

##  Integration with Caravel

- Uses Wishbone bus for configuration and control
- Interfaces with GPIO for packet I/O (or external PHY)
- Integrated into `user_project_wrapper`

---

##  Verification Plan

- RTL simulation using cocotb
- Functional testbenches for:
  - Packet parsing
  - Rule matching
  - Flow counting
- Gate-level simulation (GLS)
- STA using OpenSTA

---

##  Implementation Plan

- RTL Design: Verilog
- Flow: OpenLane (SKY130)
- Verification: cocotb + Verilator
- Physical Design: Automated via OpenLane

---

##  Deliverables

- GDSII layout
- RTL source code
- Testbenches (RTL + GLS)
- PCBA design (KiCad)
- Firmware
- Documentation and demo video

---

##  Target Applications

## Target Applications

### Industrial Secure Gateway
NetStream enables deterministic, low-latency filtering of industrial network traffic by enforcing strict rule-based communication policies at the gateway level.

### Traffic Prioritization (QoS)
The design supports real-time classification and prioritization of packets, ensuring that critical control data is transmitted with minimal delay.

### Edge IoT Data Filtering
NetStream reduces bandwidth and processing overhead by filtering and processing IoT traffic locally before transmission to the cloud.

### Hardware Firewall
The match-action pipeline enables efficient rule-based packet filtering for secure edge deployments.

---

##  Feasibility

- Fits within Caravel user area (~10 mm² constraint)
- Modular design allows scaling
- Uses open-source toolchain (OpenLane, SKY130)

---

##  Timeline

- Proposal Submission: March 25
- RTL + Verification: April
- Tapeout Submission: April 30

---

##  License

Apache 2.0 

---

##  Author

Adhitya Santhanam

---

##  Repository Structure

(Will follow Caravel user project template)

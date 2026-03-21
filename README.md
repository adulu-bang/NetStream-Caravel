# NetStream: Edge Network Processing SoC (Caravel-Based)

##  Overview

NetStream is a custom silicon-based network packet processing accelerator designed for edge IoT and industrial gateway applications.

The project aims to deliver a low-cost, programmable hardware module capable of real-time packet inspection, filtering, and telemetry extraction, integrated within the Caravel SoC framework.

Unlike traditional software-based packet processing, NetStream offloads critical networking tasks into dedicated hardware, reducing latency, improving throughput, and lowering CPU overhead.

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

- Industrial IoT gateways
- Edge routers
- Smart infrastructure monitoring
- Secure embedded networking nodes

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

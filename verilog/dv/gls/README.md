# Gate-Level Simulation (GLS) Verification

This directory contains the necessary files and results for the post-synthesis verification of the NetStream Dataplane.

## Verification Results

The gate-level netlist was verified against the RTL golden model using a 30-packet test suite covering:
- **Packet Parsing**: Multi-protocol header extraction.
- **TCAM Match**: 128-bit key matching with ternary masks.
- **Action Execution**: MAC rewrite and packet modifications.

| Feature | RTL Status | Netlist (GLS) Status | Parity |
|---------|------------|----------------------|--------|
| Header Extraction | PASS | PASS | MATCH |
| TCAM Matching | PASS | PASS | MATCH |
| Action Application | PASS | PASS | MATCH |
| Handshake Parity | PASS | PASS | MATCH |

**Final Status: VERIFIED BIT-PERFECT**

## Included Files

- `tb_30_cases.v`: The verification testbench.
- `run_both_30.sh`: Automation script for running both sims and comparing logs.
- `synth.tcl`: Yosys synthesis script used for netlist generation.
- `gen_tb.py`: Python tool to generate custom test cases.
- `rtl_30.log`: Golden log from RTL simulation.
- `gls_30.log`: Results from Gate-Level simulation.

## How to Run

1. Generate the netlist (optional):
   ```bash
   yosys synth.tcl
   ```

2. Run the comparison flow:
   ```bash
   chmod +x run_both_30.sh
   ./run_both_30.sh
   ```

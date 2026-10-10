# 4-bit ALU RTL-to-GDSII (Sky130, LibreLane)
- Verilog-2001 only. Registered inputs/outputs (clk, rst_n).
- Dirs: src/ tb/ sim/ logs/ librelane/ docs/
- Never print full tool logs. Redirect to logs/<step>.log, then read only the tail, the error lines, or the metrics.
- Simulation: iverilog -g2001 + vvp. Cross-check: Vivado xsim, no FPGA synthesis.
- ASIC flow: LibreLane via Docker, sky130A. Check variable names against the official docs, don't guess.
- Don't add features beyond the approved plan. Don't run sudo.
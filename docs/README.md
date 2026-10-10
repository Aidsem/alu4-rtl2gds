# alu4: 4-bit ALU, RTL to GDSII (Sky130, LibreLane)

## Design summary

- Top module `alu4` in `src/alu4.v` (Verilog-2001).
- Inputs `a[3:0]`, `b[3:0]`, `op[2:0]`; outputs `y[3:0]` and flags `c`, `z`, `n`, `v`.
- Inputs and outputs are registered on `clk`. Reset `rst_n` is asynchronous, active low, and clears every register.
- Latency: operands applied before clock edge k appear on the outputs after edge k+1.
- Flags: `c` = carry (ADD), borrow (SUB, 1 when A < B unsigned), or the bit shifted out (SHL, SHR). `z` = (y == 0). `n` = y[3]. `v` = signed overflow (ADD, SUB only; 0 otherwise).

## Opcodes

| op  | name | result            | c                | v        |
|-----|------|-------------------|------------------|----------|
| 000 | ADD  | A + B             | carry-out        | overflow |
| 001 | SUB  | A - B             | borrow (A < B)   | overflow |
| 010 | AND  | A & B             | 0                | 0        |
| 011 | OR   | A \| B            | 0                | 0        |
| 100 | XOR  | A ^ B             | 0                | 0        |
| 101 | NOT  | ~A (B ignored)    | 0                | 0        |
| 110 | SHL  | {A[2:0], 0}       | A[3]             | 0        |
| 111 | SHR  | {0, A[3:1]} logical | A[0]           | 0        |

## Simulate

Run from the project root so the VCD lands in `sim/`. The testbench is exhaustive (8 opcodes x 16 x 16 = 2048 vectors) plus reset checks.

```
iverilog -g2001 -o sim/alu4.vvp src/alu4.v tb/tb_alu4.v
vvp sim/alu4.vvp
```

Expected last line: `PASS: 2048/2048 vectors, 0 errors (+ reset checks ok)`.

Cross-check with Vivado xsim (simulation only, no FPGA synthesis): compile with `xvlog`, elaborate with `xelab -timescale 1ns/1ps tb_alu4 -s tb_snap`, run with `xsim tb_snap -R`. Logs are in `logs/`.

## Run the flow

LibreLane 3.0.16 via Docker, PDK sky130A. Config: `librelane/config.json`; constraints: `librelane/alu4.sdc`; variable notes: `librelane/CONFIG_NOTES.md`.

```
source .venv/bin/activate
librelane --dockerized librelane/config.json > logs/flow.log 2>&1
tail -n 20 logs/flow.log
```

Results land in `librelane/runs/<RUN_TAG>/`. The final GDS is `final/gds/alu4.gds`; metrics are in `final/metrics.json`.

## Results (run RUN_2026-10-10_14-18-25, clock 10 ns)

Signoff STA, worst slack in ns across all corners:

| Corner (nom / min / max RC)  | Setup WS (ns) | Hold WS (ns) |
|------------------------------|---------------|--------------|
| tt 025C 1v80                 | +6.60         | +0.42        |
| ss 100C 1v60                 | +5.13         | +1.09        |
| ff n40C 1v95                 | +6.99         | +0.16        |
| **Worst overall**            | **+5.13**     | **+0.16**    |

| Check                    | Result            |
|--------------------------|-------------------|
| Setup / hold violations  | 0 / 0             |
| Max slew / max cap       | 0 / 0             |
| Route DRC                | 0 (19 on pass 1) |
| Magic DRC / KLayout DRC  | 0 / 0             |
| LVS errors               | 0                 |
| Antenna violations       | 0                 |
| Die area                 | 22500 um2 (150 x 150) |
| Std cells (logic)        | 114 (+245 tap, 4440 fill) |
| Wirelength               | 2748 um           |
| Total power              | 0.26 mW           |

## Screenshot of the layout in KLayout

1. Run `klayout librelane/runs/RUN_2026-10-10_14-18-25/final/klayout_gds/alu4.klayout.gds` (or `final/gds/alu4.gds`).
2. Press `Shift+F` to fit the die to the window.
3. Show all hierarchy: Display menu, "Full Hierarchy" (or press `*`).
4. Save: File menu, "Save Layout As Image..." (PNG, at least 1600 px wide). Save it as `docs/layout.png`.

A LibreLane-rendered image is already at `librelane/runs/RUN_2026-10-10_14-18-25/final/render/alu4.png`.

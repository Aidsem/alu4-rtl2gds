# config.json notes

Variable names checked against librelane.readthedocs.io (reference/common_flow_vars, reference/step_config_vars)
and the installed LibreLane 3.0.16 source. Each entry is one line.

- `DESIGN_NAME`: top module name; must match `module alu4` in `src/alu4.v`.
- `VERILOG_FILES`: RTL input list; `dir::` resolves relative to the folder holding this config.
- `CLOCK_PORT`: name of the clock input port; used when the flow builds its constraints.
- `CLOCK_PERIOD`: clock period in ns (10 = 100 MHz); loose on purpose so the first run tests the flow, not timing closure.
- `PNR_SDC_FILE`: SDC used by all place-and-route steps; replaces the generated fallback constraints.
- `SIGNOFF_SDC_FILE`: SDC used by the post-route multi-corner signoff STA (OpenROAD.STAPostPNR).
- `FP_SIZING`: `absolute` means the floorplan uses `DIE_AREA` instead of deriving size from `FP_CORE_UTIL`.
- `DIE_AREA`: die rectangle `[x0, y0, x1, y1]` in µm; 150x150 leaves room for 21 I/O pins and the power grid.
- `PL_TARGET_DENSITY_PCT`: global-placement cell density in %; 50 keeps cells clustered in the mostly empty die instead of spreading them out.

Left at default on purpose: `CORE_AREA` (not set, so core margins are derived from the die), `PDN_VPITCH` / `PDN_HPITCH` (PDK values),
`RUN_ANTENNA_REPAIR` (true), `RUN_LVS`, `RUN_MAGIC_DRC`, `RUN_KLAYOUT_DRC`, `RUN_KLAYOUT_XOR`, `RUN_LINTER` (all true).

Names that differ from OpenLane 1: `PDN_VPITCH` was `FP_PDN_VPITCH`, `PL_TARGET_DENSITY_PCT` was `PL_TARGET_DENSITY`,
`FALLBACK_SDC` was `FALLBACK_SDC_FILE`.

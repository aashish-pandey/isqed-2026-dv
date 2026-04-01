// filelist.f — Compilation file list for nexus_uart Task 1.1 submission
// Usage (Xcelium): xrun -f filelist.f +UVM_TESTNAME=uart_base_test
// Usage (VCS):     vcs -f filelist.f +UVM_TESTNAME=uart_base_test
// Usage (Questa):  vlog -f filelist.f (then vsim uart_tb_top)
//
// Assumes this file is run from: submission/task_1_1/nexus_uart/
// RTL root is at:                ../../../../  (adjust PROJ_ROOT as needed)

// ── Simulator flags (uncomment for your tool) ─────────────────────────────
// Xcelium:  -sv -uvm -access +rwc
// VCS:      -sverilog -ntb_opts uvm-1.2
// Questa:   -sv

// ── Project root (relative to this filelist) ─────────────────────────────
+define+PROJ_ROOT=../../../..

// ── DUT sources ───────────────────────────────────────────────────────────
../../../duts/common/dv_common_pkg.sv
../../../duts/nexus_uart/nexus_uart.sv

// ── TL-UL agent ───────────────────────────────────────────────────────────
agents/tl_ul/tl_ul_if.sv
agents/tl_ul/tl_ul_seq_item.sv
agents/tl_ul/tl_ul_sequencer.sv
agents/tl_ul/tl_ul_driver.sv
agents/tl_ul/tl_ul_monitor.sv
agents/tl_ul/tl_ul_sequences.sv
agents/tl_ul/tl_ul_agent.sv

// // ── uart protocol agent ───────────────────────────────────────────────────
agents/uart/uart_if.sv
agents/uart/uart_seq_item.sv
agents/uart/uart_driver.sv
agents/uart/uart_monitor.sv
agents/uart/uart_sequences.sv
agents/uart/uart_agent.sv

// // // ── Scoreboard ────────────────────────────────────────────────────────────
scoreboard/uart_scoreboard.sv

// // // ── Environment ───────────────────────────────────────────────────────────
env/uart_coverage.sv
env/uart_env.sv

// // // ── Testbench top ─────────────────
// tb/uart_base_test.sv
// tb/uart_tb_top.sv

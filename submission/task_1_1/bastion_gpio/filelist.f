// filelist.f — Compilation file list for bastion_gpio Task 1.1 submission
// Usage (Xcelium): xrun -f filelist.f +UVM_TESTNAME=gpio_base_test
// Usage (VCS):     vcs -f filelist.f +UVM_TESTNAME=gpio_base_test
// Usage (Questa):  vlog -f filelist.f (then vsim gpio_tb_top)
//
// Assumes this file is run from: submission/task_1_1/bastion_gpio/
// RTL root is at:                ../../../../  (adjust PROJ_ROOT as needed)

// ── Simulator flags (uncomment for your tool) ─────────────────────────────
// Xcelium:  -sv -uvm -access +rwc
// VCS:      -sverilog -ntb_opts uvm-1.2
// Questa:   -sv

// ── Project root (relative to this filelist) ─────────────────────────────
+define+PROJ_ROOT=../../../..

// ── DUT sources ───────────────────────────────────────────────────────────
../../../duts/common/dv_common_pkg.sv
../../../duts/bastion_gpio/bastion_gpio.sv

// ── TL-UL agent ───────────────────────────────────────────────────────────
agents/tl_ul/tl_ul_seq_item.sv
// agents/tl_ul/tl_ul_sequencer.sv
// agents/tl_ul/tl_ul_driver.sv
// agents/tl_ul/tl_ul_monitor.sv
// agents/tl_ul/tl_ul_sequences.sv
// agents/tl_ul/tl_ul_agent.sv

// // ── GPIO protocol agent ───────────────────────────────────────────────────
// agents/gpio/gpio_seq_item.sv
// agents/gpio/gpio_driver.sv
// agents/gpio/gpio_monitor.sv
// agents/gpio/gpio_sequences.sv

// // ── Scoreboard ────────────────────────────────────────────────────────────
// scoreboard/gpio_scoreboard.sv

// // ── Environment ───────────────────────────────────────────────────────────
// env/gpio_coverage.sv
// env/gpio_env.sv

// // ── Testbench top (includes gpio_if interface definition) ─────────────────
// tb/gpio_tb_top.sv

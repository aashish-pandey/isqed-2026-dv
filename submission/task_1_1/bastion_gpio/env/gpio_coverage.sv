//=============================================================================
// gpio_coverage.sv
// Functional coverage for bastion_gpio.
// Covers: CSR address access patterns, interrupt modes, pin directions,
// masked write operations, and edge detection scenarios.
//=============================================================================
`ifndef GPIO_COVERAGE_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
`define GPIO_COVERAGE_SV

class gpio_coverage extends uvm_subscriber #(tl_ul_seq_item);
  `uvm_component_utils(gpio_coverage)

  virtual interface gpio_if gpio_vif;

  // ── Covergroup: CSR address access ───────────────────────────────────────
  covergroup cg_csr_access;
    cp_addr: coverpoint item.addr[5:0] {
      bins data_in              = {6'h00};
      bins data_out             = {6'h04};
      bins dir                  = {6'h08};
      bins intr_state           = {6'h0C};
      bins intr_enable          = {6'h10};
      bins intr_test            = {6'h14};
      bins intr_ctrl_en_rising  = {6'h18};
      bins intr_ctrl_en_falling = {6'h1C};
      bins intr_ctrl_en_lvlhigh = {6'h20};
      bins intr_ctrl_en_lvllow  = {6'h24};
      bins masked_out_lower     = {6'h28};
      bins masked_out_upper     = {6'h2C};
    }
    cp_op: coverpoint item.opcode {
      bins write = {3'd0, 3'd1};
      bins read  = {3'd4};
    }
    cx_addr_op: cross cp_addr, cp_op;
  endgroup

  // ── Covergroup: DATA_OUT values ───────────────────────────────────────────
  covergroup cg_data_out;
    cp_data_out: coverpoint item.data {
      bins all_zeros = {32'h00000000};
      bins all_ones  = {32'hFFFFFFFF};
      bins lower_half_only = {[32'h00000001:32'h0000FFFF]};
      bins upper_half_only = {[32'h00010000:32'hFFFFFFFE]};
      bins other = default;
    }
  endgroup

  // ── Covergroup: DIR register values ───────────────────────────────────────
  covergroup cg_dir;
    cp_dir: coverpoint item.data {
      bins all_input  = {32'h00000000};
      bins all_output = {32'hFFFFFFFF};
      bins mixed      = default;
    }
  endgroup

  // ── Covergroup: Interrupt modes ───────────────────────────────────────────
  covergroup cg_intr_mode;
    cp_rising_nonzero:  coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h18) {
      bins enabled = {1'b1};
    }
    cp_falling_nonzero: coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h1C) {
      bins enabled = {1'b1};
    }
    cp_lvlhigh_nonzero: coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h20) {
      bins enabled = {1'b1};
    }
    cp_lvllow_nonzero:  coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h24) {
      bins enabled = {1'b1};
    }
  endgroup

  // ── Covergroup: Masked write mask patterns ────────────────────────────────
  covergroup cg_masked_write;
    cp_mask_pattern: coverpoint item.data[31:16] {
      bins all_masked    = {16'hFFFF};
      bins none_masked   = {16'h0000};
      bins partial_mask  = default;
    }
    cp_which_reg: coverpoint item.addr[5:0] {
      bins lower = {6'h28};
      bins upper = {6'h2C};
    }
    cx_mask_reg: cross cp_mask_pattern, cp_which_reg;
  endgroup

  // ── Covergroup: INTR_TEST usage ───────────────────────────────────────────
  covergroup cg_intr_test;
    cp_intr_test_written: coverpoint (item.data != 0) {
      bins test_set = {1'b1};
    }
  endgroup

  // ── Covergroup: INTR_STATE W1C clearing ──────────────────────────────────
  covergroup cg_intr_clear;
    cp_clear_pattern: coverpoint item.data {
      bins all_clear   = {32'hFFFFFFFF};
      bins partial_clr = default;
    }
  endgroup

  tl_ul_seq_item item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_csr_access   = new();
    cg_data_out      = new();
    cg_dir           = new();
    cg_intr_mode     = new();
    cg_masked_write  = new();
    cg_intr_test     = new();
    cg_intr_clear    = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual gpio_if)::get(this, "", "gpio_vif", gpio_vif))
      `uvm_fatal("NO_VIF", "gpio_coverage: gpio_vif not found")
  endfunction

  function void write(tl_ul_seq_item t);
    item = t;

    // Always sample CSR access coverage
    cg_csr_access.sample();

    if (item.is_write()) begin
      case (item.addr[5:0])
        6'h04: cg_data_out.sample();
        6'h08: cg_dir.sample();
        6'h0C: cg_intr_clear.sample();
        6'h14: cg_intr_test.sample();
        6'h18, 6'h1C, 6'h20, 6'h24: cg_intr_mode.sample();
        6'h28, 6'h2C: cg_masked_write.sample();
        default: ;
      endcase
    end
  endfunction

endclass

`endif // GPIO_COVERAGE_SV

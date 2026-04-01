import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_coverage extends uvm_subscriber #(tl_ul_seq_item);
  `uvm_component_utils(gpio_coverage)

  tl_ul_seq_item item;

  // CSR address access patterns
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

  // DIR register — all input, all output, mixed
  covergroup cg_dir;
    cp_dir: coverpoint item.data {
      bins all_input  = {32'h00000000};
      bins all_output = {32'hFFFFFFFF};
      bins mixed      = default;
    }
  endgroup

  // Interrupt modes enabled
  covergroup cg_intr_mode;
    cp_rising:  coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h18) { bins en = {1}; }
    cp_falling: coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h1C) { bins en = {1}; }
    cp_lvlhigh: coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h20) { bins en = {1}; }
    cp_lvllow:  coverpoint (item.data != 0) iff (item.addr[5:0] == 6'h24) { bins en = {1}; }
  endgroup

  // Masked write patterns
  covergroup cg_masked_write;
    cp_mask: coverpoint item.data[31:16] {
      bins all_masked  = {16'hFFFF};
      bins none_masked = {16'h0000};
      bins partial     = default;
    }
    cp_reg: coverpoint item.addr[5:0] {
      bins lower = {6'h28};
      bins upper = {6'h2C};
    }
    cx_mask_reg: cross cp_mask, cp_reg;
  endgroup

  // INTR_TEST written
  covergroup cg_intr_test;
    cp_test: coverpoint (item.data != 0) { bins set = {1}; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_csr_access  = new();
    cg_dir         = new();
    cg_intr_mode   = new();
    cg_masked_write = new();
    cg_intr_test   = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  function void write(tl_ul_seq_item t);
    item = t;
    cg_csr_access.sample();
    if (item.is_write()) begin
      case (item.addr[5:0])
        6'h08: cg_dir.sample();
        6'h14: cg_intr_test.sample();
        6'h18, 6'h1C, 6'h20, 6'h24: cg_intr_mode.sample();
        6'h28, 6'h2C: cg_masked_write.sample();
        default: ;
      endcase
    end
  endfunction

endclass
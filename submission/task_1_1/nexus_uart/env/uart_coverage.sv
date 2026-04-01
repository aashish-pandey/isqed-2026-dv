import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_coverage extends uvm_subscriber #(tl_ul_seq_item);
  `uvm_component_utils(uart_coverage)

  tl_ul_seq_item item;

  // CSR address access patterns
  covergroup cg_csr_access;
    cp_addr: coverpoint item.addr[4:0] {
      bins ctrl        = {5'h00};
      bins status      = {5'h04};
      bins txdata      = {5'h08};
      bins rxdata      = {5'h0C};
      bins fifo_ctrl   = {5'h10};
      bins intr_state  = {5'h14};
      bins intr_enable = {5'h18};
      bins intr_test   = {5'h1C};
    }
    cp_op: coverpoint item.opcode {
      bins write = {3'd0, 3'd1};
      bins read  = {3'd4};
    }
    cx_addr_op: cross cp_addr, cp_op;
  endgroup

  // CTRL register fields
  covergroup cg_ctrl;
    cp_tx_en:   coverpoint item.data[0]     { bins on = {1}; bins off = {0}; }
    cp_rx_en:   coverpoint item.data[1]     { bins on = {1}; bins off = {0}; }
    cp_parity:  coverpoint item.data[19:18] {
      bins none = {2'b00};
      bins even = {2'b01};
      bins odd  = {2'b10};
    }
    cp_stop:    coverpoint item.data[20]    { bins one = {0}; bins two = {1}; }
    cp_loopback: coverpoint item.data[21]   { bins on = {1}; bins off = {0}; }
  endgroup

  // FIFO_CTRL — reset and watermark
  covergroup cg_fifo_ctrl;
    cp_tx_rst: coverpoint item.data[10] { bins set = {1}; }
    cp_rx_rst: coverpoint item.data[11] { bins set = {1}; }
    cp_tx_wm:  coverpoint item.data[4:0] {
      bins min     = {5'd1};
      bins mid     = {[5'd2:5'd15]};
      bins max     = {5'd31};
    }
  endgroup

  // Interrupt enable patterns
  covergroup cg_intr_enable;
    cp_intr_en: coverpoint item.data[6:0] {
      bins none    = {7'h00};
      bins all     = {7'h7F};
      bins partial = default;
    }
  endgroup

  // INTR_TEST
  covergroup cg_intr_test;
    cp_test: coverpoint item.data[6:0] {
      bins nonzero = {[7'h01:7'h7F]};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_csr_access  = new();
    cg_ctrl        = new();
    cg_fifo_ctrl   = new();
    cg_intr_enable = new();
    cg_intr_test   = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  function void write(tl_ul_seq_item t);
    item = t;
    cg_csr_access.sample();
    if (item.is_write()) begin
      case (item.addr[4:0])
        5'h00: cg_ctrl.sample();
        5'h10: cg_fifo_ctrl.sample();
        5'h18: cg_intr_enable.sample();
        5'h1C: cg_intr_test.sample();
        default: ;
      endcase
    end
  endfunction

endclass
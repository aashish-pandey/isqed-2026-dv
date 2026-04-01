import uvm_pkg::*;
`include "uvm_macros.svh"

`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)

class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)

  uvm_analysis_imp_write #(tl_ul_seq_item, uart_scoreboard) aimp_write;
  uvm_analysis_imp_read  #(tl_ul_seq_item, uart_scoreboard) aimp_read;

  // Shadow registers
  bit [31:0] shadow_ctrl;
  bit [31:0] shadow_fifo_ctrl;
  bit [31:0] shadow_intr_enable;

  int unsigned passed;
  int unsigned failed;

  localparam bit [31:0] ADDR_CTRL        = 32'h00;
  localparam bit [31:0] ADDR_STATUS      = 32'h04;
  localparam bit [31:0] ADDR_TXDATA      = 32'h08;
  localparam bit [31:0] ADDR_RXDATA      = 32'h0C;
  localparam bit [31:0] ADDR_FIFO_CTRL   = 32'h10;
  localparam bit [31:0] ADDR_INTR_STATE  = 32'h14;
  localparam bit [31:0] ADDR_INTR_ENABLE = 32'h18;
  localparam bit [31:0] ADDR_INTR_TEST   = 32'h1C;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    aimp_write = new("aimp_write", this);
    aimp_read  = new("aimp_read",  this);
    // FIFO_CTRL reset: tx_wm=1, rx_wm=1
    shadow_fifo_ctrl  = 32'h00000021;
    shadow_ctrl       = 32'h0;
    shadow_intr_enable = 32'h0;
  endfunction

  function void write_write(tl_ul_seq_item txn);
    bit [31:0] addr;
    bit [31:0] wdata;
    addr  = {txn.addr[31:2], 2'b00};
    wdata = txn.data;

    case (addr)
      ADDR_CTRL:        shadow_ctrl = wdata;
      ADDR_FIFO_CTRL:   shadow_fifo_ctrl = wdata;
      ADDR_INTR_ENABLE: shadow_intr_enable = wdata;
      // TXDATA, INTR_STATE, INTR_TEST: no shadow needed
      default: ;
    endcase

    // Check no unexpected error on valid write addresses
    if (txn.error) begin
      if (addr inside {ADDR_CTRL, ADDR_TXDATA, ADDR_FIFO_CTRL,
                       ADDR_INTR_STATE, ADDR_INTR_ENABLE, ADDR_INTR_TEST}) begin
        `uvm_error("SB_ERR",
          $sformatf("Unexpected error on WRITE addr=0x%08h", addr))
      end
    end
  endfunction

  function void write_read(tl_ul_seq_item txn);
    bit [31:0] addr;
    bit [31:0] exp_data;
    bit        skip;
    addr = {txn.addr[31:2], 2'b00};
    skip = 0;

    case (addr)
      ADDR_CTRL:        exp_data = shadow_ctrl;
      ADDR_STATUS:      skip = 1;  // hardware-driven FIFO levels
      ADDR_TXDATA:      skip = 1;  // write-only, returns error
      ADDR_RXDATA:      skip = 1;  // hardware-driven RX FIFO
      ADDR_FIFO_CTRL:   exp_data = shadow_fifo_ctrl;
      ADDR_INTR_STATE:  skip = 1;  // hardware-driven interrupts
      ADDR_INTR_ENABLE: exp_data = shadow_intr_enable;
      ADDR_INTR_TEST:   exp_data = 32'h0;  // always reads 0
      default:          exp_data = 32'h0;
    endcase

    if (skip) return;

    if (txn.rdata !== exp_data) begin
      failed++;
      `uvm_error("SB_MISMATCH",
        $sformatf("READ addr=0x%08h DUT=0x%08h EXP=0x%08h",
                  addr, txn.rdata, exp_data))
    end else begin
      passed++;
      `uvm_info("SB_OK",
        $sformatf("READ addr=0x%08h data=0x%08h OK", addr, txn.rdata), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("Scoreboard: %0d passed, %0d failed",
              passed, failed), UVM_NONE)
    if (failed > 0)
      `uvm_error("SB_FAIL", "Scoreboard detected mismatches")
  endfunction

endclass
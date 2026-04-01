import uvm_pkg::*;
`include "uvm_macros.svh"

`uvm_analysis_imp_decl(_write)
`uvm_analysis_imp_decl(_read)

class gpio_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gpio_scoreboard)

  uvm_analysis_imp_write #(tl_ul_seq_item, gpio_scoreboard) aimp_write;
  uvm_analysis_imp_read  #(tl_ul_seq_item, gpio_scoreboard) aimp_read;

  bit [31:0] shadow_data_out;
  bit [31:0] shadow_dir;
  bit [31:0] shadow_intr_state;
  bit [31:0] shadow_intr_enable;
  bit [31:0] shadow_intr_ctrl_rising;
  bit [31:0] shadow_intr_ctrl_falling;
  bit [31:0] shadow_intr_ctrl_lvlhigh;
  bit [31:0] shadow_intr_ctrl_lvllow;

  int unsigned passed;
  int unsigned failed;

  localparam bit [31:0] ADDR_DATA_IN              = 32'h00;
  localparam bit [31:0] ADDR_DATA_OUT             = 32'h04;
  localparam bit [31:0] ADDR_DIR                  = 32'h08;
  localparam bit [31:0] ADDR_INTR_STATE           = 32'h0C;
  localparam bit [31:0] ADDR_INTR_ENABLE          = 32'h10;
  localparam bit [31:0] ADDR_INTR_TEST            = 32'h14;
  localparam bit [31:0] ADDR_INTR_CTRL_EN_RISING  = 32'h18;
  localparam bit [31:0] ADDR_INTR_CTRL_EN_FALLING = 32'h1C;
  localparam bit [31:0] ADDR_INTR_CTRL_EN_LVLHIGH = 32'h20;
  localparam bit [31:0] ADDR_INTR_CTRL_EN_LVLLOW  = 32'h24;
  localparam bit [31:0] ADDR_MASKED_OUT_LOWER     = 32'h28;
  localparam bit [31:0] ADDR_MASKED_OUT_UPPER     = 32'h2C;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    aimp_write = new("aimp_write", this);
    aimp_read  = new("aimp_read",  this);
  endfunction

  function void write_write(tl_ul_seq_item txn);
    bit [31:0] addr;
    bit [31:0] wdata;
    addr  = {txn.addr[31:2], 2'b00};
    wdata = txn.data;
    case (addr)
      ADDR_DATA_OUT:             shadow_data_out = wdata;
      ADDR_DIR:                  shadow_dir = wdata;
      ADDR_INTR_STATE:           shadow_intr_state = shadow_intr_state & ~wdata;
      ADDR_INTR_ENABLE:          shadow_intr_enable = wdata;
      ADDR_INTR_TEST:            shadow_intr_state = shadow_intr_state | wdata;
      ADDR_INTR_CTRL_EN_RISING:  shadow_intr_ctrl_rising  = wdata;
      ADDR_INTR_CTRL_EN_FALLING: shadow_intr_ctrl_falling = wdata;
      ADDR_INTR_CTRL_EN_LVLHIGH: shadow_intr_ctrl_lvlhigh = wdata;
      ADDR_INTR_CTRL_EN_LVLLOW:  shadow_intr_ctrl_lvllow  = wdata;
      ADDR_MASKED_OUT_LOWER: begin
        for (int i = 0; i < 16; i++)
          if (wdata[i+16]) shadow_data_out[i] = wdata[i];
      end
      ADDR_MASKED_OUT_UPPER: begin
        for (int i = 0; i < 16; i++)
          if (wdata[i+16]) shadow_data_out[i+16] = wdata[i];
      end
      default: ;
    endcase
  endfunction

  function void write_read(tl_ul_seq_item txn);
    bit [31:0] addr;
    bit [31:0] exp_data;
    bit        skip;
    addr = {txn.addr[31:2], 2'b00};
    skip = 0;
    case (addr)
      ADDR_DATA_IN:              skip = 1;
      ADDR_DATA_OUT:             exp_data = shadow_data_out;
      ADDR_DIR:                  exp_data = shadow_dir;
      ADDR_INTR_STATE:           exp_data = shadow_intr_state;
      ADDR_INTR_ENABLE:          exp_data = shadow_intr_enable;
      ADDR_INTR_CTRL_EN_RISING:  exp_data = shadow_intr_ctrl_rising;
      ADDR_INTR_CTRL_EN_FALLING: exp_data = shadow_intr_ctrl_falling;
      ADDR_INTR_CTRL_EN_LVLHIGH: exp_data = shadow_intr_ctrl_lvlhigh;
      ADDR_INTR_CTRL_EN_LVLLOW:  exp_data = shadow_intr_ctrl_lvllow;
      ADDR_MASKED_OUT_LOWER:     exp_data = {16'h0, shadow_data_out[15:0]};
      ADDR_MASKED_OUT_UPPER:     exp_data = {16'h0, shadow_data_out[31:16]};
      default:                   exp_data = 32'h0;
    endcase
    if (skip) return;
    if (txn.rdata !== exp_data) begin
      failed++;
      `uvm_error("SB_MISMATCH",
        $sformatf("READ addr=0x%08h DUT=0x%08h EXP=0x%08h", addr, txn.rdata, exp_data))
    end else begin
      passed++;
      `uvm_info("SB_OK",
        $sformatf("READ addr=0x%08h data=0x%08h OK", addr, txn.rdata), UVM_HIGH)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("Scoreboard: %0d passed, %0d failed", passed, failed), UVM_NONE)
    if (failed > 0)
      `uvm_error("SB_FAIL", "Scoreboard detected mismatches")
  endfunction

endclass
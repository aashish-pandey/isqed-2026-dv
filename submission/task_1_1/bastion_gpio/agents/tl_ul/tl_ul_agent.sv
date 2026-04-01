//=============================================================================
// tl_ul_agent.sv
// Packages sequencer + driver + monitor into one UVM agent.
// Also contains the tl_ul_if interface definition.
//=============================================================================
`ifndef TL_UL_AGENT_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
`define TL_UL_AGENT_SV

//-----------------------------------------------------------------------------
// tl_ul_if — virtual interface (flat signals matching all challenge DUTs)
//-----------------------------------------------------------------------------
interface tl_ul_if (input logic clk, input logic rst_n);

  // Channel A (host → device)
  logic        a_valid;
  logic        a_ready;
  logic [2:0]  a_opcode;
  logic [31:0] a_address;
  logic [31:0] a_data;
  logic [3:0]  a_mask;
  logic [7:0]  a_source;
  logic [1:0]  a_size;

  // Channel D (device → host)
  logic        d_valid;
  logic        d_ready;
  logic [2:0]  d_opcode;
  logic [31:0] d_data;
  logic [7:0]  d_source;
  logic        d_error;

endinterface

//-----------------------------------------------------------------------------
// tl_ul_agent
//-----------------------------------------------------------------------------
class tl_ul_agent extends uvm_agent;
  `uvm_component_utils(tl_ul_agent)

  tl_ul_sequencer sequencer;
  tl_ul_driver    driver;
  tl_ul_monitor   monitor;

  // Expose monitor analysis ports for environment connections
  uvm_analysis_port #(tl_ul_seq_item) ap_write;
  uvm_analysis_port #(tl_ul_seq_item) ap_read;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = tl_ul_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = tl_ul_sequencer::type_id::create("sequencer", this);
      driver    = tl_ul_driver::type_id::create("driver",    this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);

    // Expose monitor ports upward so env can connect scoreboard/coverage
    ap_write = monitor.ap_write;
    ap_read  = monitor.ap_read;
  endfunction

endclass

`endif // TL_UL_AGENT_SV

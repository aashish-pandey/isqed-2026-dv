//=============================================================================
// tl_ul_monitor.sv
// Observes both TL-UL channels, publishes completed transactions on two
// analysis ports: ap_write (writes) and ap_read (reads).
//=============================================================================
`ifndef TL_UL_MONITOR_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
`define TL_UL_MONITOR_SV

class tl_ul_monitor extends uvm_monitor;
  `uvm_component_utils(tl_ul_monitor)

  virtual interface tl_ul_if vif;

  // Scoreboard and coverage connect to these
  uvm_analysis_port #(tl_ul_seq_item) ap_write;
  uvm_analysis_port #(tl_ul_seq_item) ap_read;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_write = new("ap_write", this);
    ap_read  = new("ap_read",  this);
    if (!uvm_config_db #(virtual tl_ul_if)::get(this, "", "tl_vif", vif))
      `uvm_fatal("NO_VIF", {"tl_ul_monitor: tl_vif not found for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);
    forever observe_one_transaction();
  endtask

  task observe_one_transaction();
    tl_ul_seq_item txn;

    // Wait for A-channel handshake
    do @(posedge vif.clk);
    while (!(vif.a_valid && vif.a_ready));

    txn          = tl_ul_seq_item::type_id::create("mon_txn");
    txn.opcode   = vif.a_opcode;
    txn.addr     = {vif.a_address[31:2], 2'b00};  // word-aligned
    txn.data     = vif.a_data;
    txn.mask     = vif.a_mask;
    txn.source   = vif.a_source;
    txn.size     = vif.a_size;

    // Wait for D-channel response
    do @(posedge vif.clk);
    while (!(vif.d_valid && vif.d_ready));

    txn.rdata = vif.d_data;
    txn.error = vif.d_error;

    `uvm_info("TL_MON", txn.convert2string(), UVM_HIGH)

    if (txn.is_write())
      ap_write.write(txn);
    else
      ap_read.write(txn);
  endtask

endclass

`endif // TL_UL_MONITOR_SV

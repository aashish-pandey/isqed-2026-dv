import uvm_pkg::*;
`include "uvm_macros.svh"

class tl_ul_agent extends uvm_agent;
  `uvm_component_utils(tl_ul_agent)

  tl_ul_sequencer sequencer;
  tl_ul_driver    driver;
  tl_ul_monitor   monitor;

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
      driver    = tl_ul_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    ap_write = monitor.ap_write;
    ap_read  = monitor.ap_read;
  endfunction

endclass
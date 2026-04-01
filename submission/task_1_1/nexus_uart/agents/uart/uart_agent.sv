import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  uvm_sequencer #(uart_seq_item) sequencer;
  uart_driver                    driver;
  uart_monitor                   monitor;

  uvm_analysis_port #(uart_seq_item) ap_uart;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = uart_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = uvm_sequencer #(uart_seq_item)::type_id::create("sequencer", this);
      driver    = uart_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    ap_uart = monitor.ap_uart;
  endfunction

endclass
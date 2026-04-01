import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_agent extends uvm_agent;
  `uvm_component_utils(gpio_agent)

  uvm_sequencer #(gpio_seq_item) sequencer;
  gpio_driver                    driver;
  gpio_monitor                   monitor;

  uvm_analysis_port #(gpio_seq_item) ap_gpio;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = gpio_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = uvm_sequencer #(gpio_seq_item)::type_id::create("sequencer", this);
      driver    = gpio_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    ap_gpio = monitor.ap_gpio;
  endfunction

endclass
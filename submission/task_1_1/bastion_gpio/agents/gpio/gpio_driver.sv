import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_driver extends uvm_driver #(gpio_seq_item);
  `uvm_component_utils(gpio_driver)

  virtual gpio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual gpio_if)::get(this, "", "gpio_vif", vif))
      `uvm_fatal("NO_VIF", "gpio_driver: gpio_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.gpio_i <= 32'h0;
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);
    forever begin
      gpio_seq_item req;
      seq_item_port.get_next_item(req);
      drive_pins(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_pins(gpio_seq_item req);
    for (int i = 0; i < 32; i++) begin
      if (req.pin_mask[i])
        vif.gpio_i[i] <= req.pin_values[i];
    end
    repeat(req.hold_cycles) @(posedge vif.clk);
  endtask

endclass
//=============================================================================
// gpio_driver.sv
// Drives gpio_i pins according to gpio_seq_item transactions.
// Handles the two-stage synchronizer latency — holds values long enough
// for them to propagate through gpio_sync_q1 → gpio_sync_q2.
//=============================================================================
`ifndef GPIO_DRIVER_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_seq_item);
  `uvm_component_utils(gpio_driver)

  virtual interface gpio_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual gpio_if)::get(this, "", "gpio_vif", vif))
      `uvm_fatal("NO_VIF", {"gpio_driver: gpio_vif not found for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    // Initialize all pins to 0
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

  task drive_pins(gpio_seq_item item);
    // Apply the masked pin values
    // Pins not in mask retain their previous driven value
    foreach (item.pin_mask[i]) begin
      if (item.pin_mask[i])
        vif.gpio_i[i] <= item.pin_values[i];
    end

    // Hold for requested cycles so synchronizer captures the value
    // Minimum useful hold = 3 cycles (2 sync stages + 1 edge detect cycle)
    repeat(item.hold_cycles) @(posedge vif.clk);
  endtask

endclass

`endif // GPIO_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_monitor extends uvm_monitor;
  `uvm_component_utils(gpio_monitor)

  virtual gpio_if vif;

  uvm_analysis_port #(gpio_seq_item) ap_gpio;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_gpio = new("ap_gpio", this);
    if (!uvm_config_db #(virtual gpio_if)::get(this, "", "gpio_vif", vif))
      `uvm_fatal("NO_VIF", "gpio_monitor: gpio_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] prev_gpio_i;
    prev_gpio_i = 32'h0;
    @(posedge vif.rst_n);
    repeat(4) @(posedge vif.clk);
    forever begin
      @(posedge vif.clk);
      if (vif.gpio_i !== prev_gpio_i) begin
        gpio_seq_item obs;
        obs             = gpio_seq_item::type_id::create("obs");
        obs.pin_values  = vif.gpio_i;
        obs.pin_mask    = 32'hFFFFFFFF;
        obs.hold_cycles = 1;
        ap_gpio.write(obs);
        prev_gpio_i = vif.gpio_i;
      end
    end
  endtask

endclass
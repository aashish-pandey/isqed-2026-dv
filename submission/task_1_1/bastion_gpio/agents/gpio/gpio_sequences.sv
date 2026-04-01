import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_base_seq extends uvm_sequence #(gpio_seq_item);
  `uvm_object_utils(gpio_base_seq)

  function new(string name = "gpio_base_seq");
    super.new(name);
  endfunction

  task drive_all(bit [31:0] values, int unsigned cycles = 6);
    gpio_seq_item item = gpio_seq_item::type_id::create("item");
    item.pin_mask    = 32'hFFFFFFFF;
    item.pin_values  = values;
    item.hold_cycles = cycles;
    start_item(item);
    finish_item(item);
  endtask

  task drive_pin(int unsigned pin, bit val, int unsigned cycles = 6);
    gpio_seq_item item = gpio_seq_item::type_id::create("item");
    item.pin_mask    = 32'h1 << pin;
    item.pin_values  = val ? (32'h1 << pin) : 32'h0;
    item.hold_cycles = cycles;
    start_item(item);
    finish_item(item);
  endtask

endclass

// Toggle all pins high then low — exercises rising and falling edge detection
class gpio_toggle_seq extends gpio_base_seq;
  `uvm_object_utils(gpio_toggle_seq)

  bit [31:0] pin_sel  = 32'hFFFFFFFF;
  int unsigned hold   = 6;

  function new(string name = "gpio_toggle_seq");
    super.new(name);
  endfunction

  task body();
    drive_all(32'h0,    hold);  // start low
    drive_all(pin_sel,  hold);  // rising edge
    drive_all(32'h0,    hold);  // falling edge
  endtask

endclass

// Randomized pin stimulus
class gpio_random_seq extends gpio_base_seq;
  `uvm_object_utils(gpio_random_seq)

  int unsigned num_txns = 16;

  function new(string name = "gpio_random_seq");
    super.new(name);
  endfunction

  task body();
    gpio_seq_item item;
    repeat (num_txns) begin
      item = gpio_seq_item::type_id::create("rand_item");
      if (!item.randomize())
        `uvm_error("RAND_FAIL", "gpio_seq_item randomization failed")
      start_item(item);
      finish_item(item);
    end
  endtask

endclass
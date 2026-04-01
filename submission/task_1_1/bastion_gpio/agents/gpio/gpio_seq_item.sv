import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_seq_item extends uvm_sequence_item;
  `uvm_object_utils(gpio_seq_item)

  rand bit [31:0] pin_mask;
  rand bit [31:0] pin_values;
  rand int unsigned hold_cycles;

  constraint c_hold_min    { hold_cycles inside {[5:20]}; }
  constraint c_mask_nonzero { pin_mask != 32'h0; }

  function new(string name = "gpio_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("[GPIO] mask=0x%08h values=0x%08h hold=%0d",
      pin_mask, pin_values, hold_cycles);
  endfunction

endclass
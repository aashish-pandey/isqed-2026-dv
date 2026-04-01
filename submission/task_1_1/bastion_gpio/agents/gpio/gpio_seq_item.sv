//=============================================================================
// gpio_seq_item.sv
// Represents a GPIO pin stimulus transaction: drive a pattern onto gpio_i
// and optionally specify how long to hold it.
//=============================================================================
`ifndef GPIO_SEQ_ITEM_SV
import uvm_pkg::*;
`include "uvm_macros.svh"
`define GPIO_SEQ_ITEM_SV

class gpio_seq_item extends uvm_sequence_item;
  `uvm_object_utils_begin(gpio_seq_item)
    `uvm_field_int(pin_mask,    UVM_ALL_ON)
    `uvm_field_int(pin_values,  UVM_ALL_ON)
    `uvm_field_int(hold_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  // Bitmask of which pins this transaction drives (1 = driven)
  rand bit [31:0] pin_mask;

  // Values to drive on the masked pins
  rand bit [31:0] pin_values;

  // How many clock cycles to hold the driven values
  rand int unsigned hold_cycles;

  constraint c_hold_reasonable {
    hold_cycles inside {[3:20]};  // minimum 3 to clear synchronizer
  }

  constraint c_mask_nonzero {
    pin_mask != 32'h0;
  }

  function new(string name = "gpio_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("[GPIO_ITEM] mask=0x%08h values=0x%08h hold=%0d cycles",
                     pin_mask, pin_values, hold_cycles);
  endfunction

endclass

`endif // GPIO_SEQ_ITEM_SV

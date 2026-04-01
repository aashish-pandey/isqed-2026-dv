import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_seq_item extends uvm_sequence_item;
  `uvm_object_utils(uart_seq_item)

  rand bit [7:0]  data;
  rand bit [15:0] baud_div;
  rand bit [1:0]  parity_mode;  // 0=none 1=even 2=odd
  rand bit        stop_bits;    // 0=1stop 1=2stop

  // Error injection
  rand bit corrupt_parity;
  rand bit corrupt_stop;

  constraint c_baud_div_valid  { baud_div != 0; }
  constraint c_parity_valid    { parity_mode != 2'b11; }
  constraint c_no_corrupt      { corrupt_parity == 0; corrupt_stop == 0; }

  function new(string name = "uart_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("[UART] data=0x%02h baud_div=%0d parity=%0d stop=%0d",
      data, baud_div, parity_mode, stop_bits);
  endfunction

endclass
import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_base_seq extends uvm_sequence #(uart_seq_item);
  `uvm_object_utils(uart_base_seq)

  bit [15:0] baud_div    = 8;
  bit [1:0]  parity_mode = 0;
  bit        stop_bits   = 0;

  function new(string name = "uart_base_seq");
    super.new(name);
  endfunction

  task send_byte(bit [7:0] data);
    uart_seq_item item = uart_seq_item::type_id::create("item");
    item.data         = data;
    item.baud_div     = baud_div;
    item.parity_mode  = parity_mode;
    item.stop_bits    = stop_bits;
    item.corrupt_parity = 0;
    item.corrupt_stop   = 0;
    start_item(item);
    finish_item(item);
  endtask

endclass

// Send a single byte
class uart_single_byte_seq extends uart_base_seq;
  `uvm_object_utils(uart_single_byte_seq)

  bit [7:0] data = 8'hA5;

  function new(string name = "uart_single_byte_seq");
    super.new(name);
  endfunction

  task body();
    send_byte(data);
  endtask

endclass

// Send multiple bytes
class uart_multi_byte_seq extends uart_base_seq;
  `uvm_object_utils(uart_multi_byte_seq)

  bit [7:0] payload [];

  function new(string name = "uart_multi_byte_seq");
    super.new(name);
  endfunction

  task body();
    foreach (payload[i])
      send_byte(payload[i]);
  endtask

endclass

// Send byte with corrupted parity — triggers rx_parity_err
class uart_parity_err_seq extends uart_base_seq;
  `uvm_object_utils(uart_parity_err_seq)

  bit [7:0] data = 8'h00;

  function new(string name = "uart_parity_err_seq");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item = uart_seq_item::type_id::create("item");
    item.data           = data;
    item.baud_div       = baud_div;
    item.parity_mode    = parity_mode;
    item.stop_bits      = stop_bits;
    item.corrupt_parity = 1;
    item.corrupt_stop   = 0;
    start_item(item);
    finish_item(item);
  endtask

endclass

// Send byte with corrupted stop bit — triggers rx_frame_err
class uart_frame_err_seq extends uart_base_seq;
  `uvm_object_utils(uart_frame_err_seq)

  bit [7:0] data = 8'h00;

  function new(string name = "uart_frame_err_seq");
    super.new(name);
  endfunction

  task body();
    uart_seq_item item = uart_seq_item::type_id::create("item");
    item.data           = data;
    item.baud_div       = baud_div;
    item.parity_mode    = parity_mode;
    item.stop_bits      = stop_bits;
    item.corrupt_parity = 0;
    item.corrupt_stop   = 1;
    start_item(item);
    finish_item(item);
  endtask

endclass
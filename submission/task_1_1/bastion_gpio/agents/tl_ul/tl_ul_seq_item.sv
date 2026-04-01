import uvm_pkg::*;
`include "uvm_macros.svh"

class tl_ul_seq_item extends uvm_sequence_item;
  `uvm_object_utils(tl_ul_seq_item)

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [3:0]  mask;
  rand bit [2:0]  opcode;
  rand bit [7:0]  source;
  rand bit [1:0]  size;
  rand int unsigned delay;

  bit [31:0] rdata;
  bit        error;

  constraint c_opcode_legal   { opcode inside {3'd0, 3'd1, 3'd4}; }
  constraint c_size_word      { size == 2'b10; }
  constraint c_mask_full      { mask == 4'hF; }
  constraint c_delay_short    { delay inside {[0:4]}; }

  function new(string name = "tl_ul_seq_item");
    super.new(name);
  endfunction

  function bit is_write();
    return (opcode == 3'd0 || opcode == 3'd1);
  endfunction

  function bit is_read();
    return (opcode == 3'd4);
  endfunction

  function string convert2string();
    return $sformatf("[TL] %s addr=0x%08h data=0x%08h rdata=0x%08h err=%0b",
      is_write() ? "WR" : "RD", addr, data, rdata, error);
  endfunction

endclass
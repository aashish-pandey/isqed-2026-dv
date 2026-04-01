import uvm_pkg::*;
`include "uvm_macros.svh"

class tl_ul_base_seq extends uvm_sequence #(tl_ul_seq_item);
  `uvm_object_utils(tl_ul_base_seq)

  function new(string name = "tl_ul_base_seq");
    super.new(name);
  endfunction

  task write_reg(bit [31:0] addr, bit [31:0] data);
    tl_ul_seq_item item = tl_ul_seq_item::type_id::create("wr");
    item.opcode = 3'd0;
    item.addr   = addr;
    item.data   = data;
    item.mask   = 4'hF;
    item.size   = 2'b10;
    item.delay  = 0;
    start_item(item);
    finish_item(item);
  endtask

  task read_reg(bit [31:0] addr, output bit [31:0] rdata);
    tl_ul_seq_item item = tl_ul_seq_item::type_id::create("rd");
    item.opcode = 3'd4;
    item.addr   = addr;
    item.data   = 32'h0;
    item.mask   = 4'hF;
    item.size   = 2'b10;
    item.delay  = 0;
    start_item(item);
    finish_item(item);
    rdata = item.rdata;
  endtask

endclass

// Single write
class tl_ul_write_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_write_seq)
  bit [31:0] addr;
  bit [31:0] data;
  function new(string name = "tl_ul_write_seq");
    super.new(name);
  endfunction
  task body();
    write_reg(addr, data);
  endtask
endclass

// Single read
class tl_ul_read_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_read_seq)
  bit [31:0] addr;
  bit [31:0] rdata;
  function new(string name = "tl_ul_read_seq");
    super.new(name);
  endfunction
  task body();
    read_reg(addr, rdata);
  endtask
endclass

// Back-to-back writes then reads
class tl_ul_burst_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_burst_seq)
  bit [31:0] addrs [];
  bit [31:0] wdata [];
  function new(string name = "tl_ul_burst_seq");
    super.new(name);
  endfunction
  task body();
    bit [31:0] rdata;
    foreach (addrs[i]) write_reg(addrs[i], wdata[i]);
    foreach (addrs[i]) read_reg(addrs[i], rdata);
  endtask
endclass

// Randomized transactions
class tl_ul_random_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_random_seq)
  bit [31:0] addr_lo = 32'h00;
  bit [31:0] addr_hi = 32'hFF;
  int unsigned num_txns = 20;
  function new(string name = "tl_ul_random_seq");
    super.new(name);
  endfunction
  task body();
    tl_ul_seq_item item;
    repeat (num_txns) begin
      item = tl_ul_seq_item::type_id::create("rand_item");
      if (!item.randomize() with {
        addr inside {[addr_lo:addr_hi]};
        addr[1:0] == 2'b00;
        opcode inside {3'd0, 3'd4};
        delay inside {[0:3]};
      }) `uvm_error("RAND_FAIL", "Randomization failed")
      start_item(item);
      finish_item(item);
    end
  endtask
endclass
//=============================================================================
// tl_ul_sequences.sv
// Reusable sequence library for TL-UL bus access.
// Provides: single write, single read, burst, and random sequences.
//=============================================================================
`ifndef TL_UL_SEQUENCES_SV
`define TL_UL_SEQUENCES_SV

//-----------------------------------------------------------------------------
// Base sequence — all TL-UL sequences extend this
//-----------------------------------------------------------------------------
class tl_ul_base_seq extends uvm_sequence #(tl_ul_seq_item);
  `uvm_object_utils(tl_ul_base_seq)

  function new(string name = "tl_ul_base_seq");
    super.new(name);
  endfunction

  // Convenience: blocking CSR write
  task write_reg(bit [31:0] addr, bit [31:0] data, bit [3:0] mask = 4'hF);
    tl_ul_seq_item item;
    item        = tl_ul_seq_item::type_id::create("wr_item");
    item.opcode = 3'd0;   // PutFullData
    item.addr   = addr;
    item.data   = data;
    item.mask   = mask;
    item.size   = 2'b10;
    item.delay  = 0;
    start_item(item);
    finish_item(item);
  endtask

  // Convenience: blocking CSR read — returns read data
  task read_reg(bit [31:0] addr, output bit [31:0] rdata);
    tl_ul_seq_item item;
    item        = tl_ul_seq_item::type_id::create("rd_item");
    item.opcode = 3'd4;   // Get
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

//-----------------------------------------------------------------------------
// tl_ul_write_seq — single CSR write
//-----------------------------------------------------------------------------
class tl_ul_write_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_write_seq)

  bit [31:0] addr;
  bit [31:0] data;
  bit [3:0]  mask = 4'hF;

  function new(string name = "tl_ul_write_seq");
    super.new(name);
  endfunction

  task body();
    write_reg(addr, data, mask);
  endtask

endclass

//-----------------------------------------------------------------------------
// tl_ul_read_seq — single CSR read
//-----------------------------------------------------------------------------
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

//-----------------------------------------------------------------------------
// tl_ul_burst_seq — back-to-back writes then reads to an address list
//-----------------------------------------------------------------------------
class tl_ul_burst_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_burst_seq)

  // Caller populates these before starting
  bit [31:0] addrs [];
  bit [31:0] wdata [];

  function new(string name = "tl_ul_burst_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rdata;
    foreach (addrs[i]) begin
      write_reg(addrs[i], wdata[i]);
    end
    foreach (addrs[i]) begin
      read_reg(addrs[i], rdata);
      `uvm_info("BURST_SEQ", $sformatf("READ addr=0x%08h data=0x%08h", addrs[i], rdata), UVM_MEDIUM)
    end
  endtask

endclass

//-----------------------------------------------------------------------------
// tl_ul_random_seq — randomized address/data/delay transactions
//-----------------------------------------------------------------------------
class tl_ul_random_seq extends tl_ul_base_seq;
  `uvm_object_utils(tl_ul_random_seq)

  // Legal address range — set by the test before starting
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
        addr[1:0] == 2'b00;          // word-aligned
        opcode inside {3'd0, 3'd4};  // writes and reads only
        delay inside {[0:3]};
      }) `uvm_error("RAND_FAIL", "Randomization failed in tl_ul_random_seq")
      start_item(item);
      finish_item(item);
    end
  endtask

endclass

`endif // TL_UL_SEQUENCES_SV

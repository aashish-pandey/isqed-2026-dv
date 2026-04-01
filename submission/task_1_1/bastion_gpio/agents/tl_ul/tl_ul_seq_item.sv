//=============================================================================
// tl_ul_seq_item.sv
// TL-UL transaction item — reusable across all DUTs.
// Fields match the flat signal interface used in the ISQED-2026 challenge.
//=============================================================================
`ifndef TL_UL_SEQ_ITEM_SV
`define TL_UL_SEQ_ITEM_SV

class tl_ul_seq_item extends uvm_sequence_item;
  `uvm_object_utils_begin(tl_ul_seq_item)
    `uvm_field_int(addr,    UVM_ALL_ON)
    `uvm_field_int(data,    UVM_ALL_ON)
    `uvm_field_int(mask,    UVM_ALL_ON)
    `uvm_field_int(opcode,  UVM_ALL_ON)
    `uvm_field_int(source,  UVM_ALL_ON)
    `uvm_field_int(size,    UVM_ALL_ON)
    `uvm_field_int(delay,   UVM_ALL_ON)
    `uvm_field_int(rdata,   UVM_ALL_ON)
    `uvm_field_int(error,   UVM_ALL_ON)
  `uvm_object_utils_end

  // ── Channel A (stimulus) ──────────────────────────────────────────────────
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit [3:0]  mask;
  rand bit [2:0]  opcode;   // 0=PutFullData  1=PutPartialData  4=Get
  rand bit [7:0]  source;
  rand bit [1:0]  size;     // 0=1B  1=2B  2=4B
  rand int unsigned delay;  // idle cycles before driving this transaction

  // ── Channel D (response, filled by driver) ────────────────────────────────
  bit [31:0] rdata;
  bit        error;

  // ── Constraints ───────────────────────────────────────────────────────────
  constraint c_opcode_legal {
    opcode inside {3'd0, 3'd1, 3'd4};
  }

  constraint c_size_word {
    size == 2'b10;   // default: 32-bit word access
  }

  constraint c_mask_full {
    mask == 4'hF;    // default: all byte lanes enabled
  }

  constraint c_delay_reasonable {
    delay inside {[0:4]};
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  function bit is_write();
    return (opcode == 3'd0 || opcode == 3'd1);
  endfunction

  function bit is_read();
    return (opcode == 3'd4);
  endfunction

  function new(string name = "tl_ul_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf(
      "[TL-UL] %s addr=0x%08h data=0x%08h mask=0x%01h src=%0d | rdata=0x%08h err=%0b",
      is_write() ? "WR" : "RD",
      addr, data, mask, source, rdata, error
    );
  endfunction

endclass

`endif // TL_UL_SEQ_ITEM_SV

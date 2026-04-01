//=============================================================================
// tl_ul_sequencer.sv
// Standard UVM sequencer — no customization needed for TL-UL.
//=============================================================================
`ifndef TL_UL_SEQUENCER_SV
`define TL_UL_SEQUENCER_SV

class tl_ul_sequencer extends uvm_sequencer #(tl_ul_seq_item);
  `uvm_component_utils(tl_ul_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // TL_UL_SEQUENCER_SV

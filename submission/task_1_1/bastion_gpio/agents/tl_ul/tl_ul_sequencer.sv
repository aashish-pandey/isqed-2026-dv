import uvm_pkg::*;
`include "uvm_macros.svh"

class tl_ul_sequencer extends uvm_sequencer #(tl_ul_seq_item);
  `uvm_component_utils(tl_ul_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
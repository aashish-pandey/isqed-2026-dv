import uvm_pkg::*;
`include "uvm_macros.svh"

class tl_ul_driver extends uvm_driver #(tl_ul_seq_item);
  `uvm_component_utils(tl_ul_driver)

  virtual tl_ul_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual tl_ul_if)::get(this, "", "tl_vif", vif))
      `uvm_fatal("NO_VIF", "tl_ul_driver: tl_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    tl_ul_seq_item req;
    idle_bus();
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(tl_ul_seq_item req);
    // Drive Channel A
    @(posedge vif.clk);
    vif.a_valid   <= 1;
    vif.a_opcode  <= req.opcode;
    vif.a_address <= req.addr;
    vif.a_data    <= req.data;
    vif.a_mask    <= req.mask;
    vif.a_source  <= req.source;
    vif.a_size    <= req.size;
    vif.d_ready   <= 1;
    // Hold until a_ready
    while (!vif.a_ready) @(posedge vif.clk);
    // Deassert valid
    @(posedge vif.clk);
    vif.a_valid <= 0;
    // Wait for d_valid
    while (!vif.d_valid) @(posedge vif.clk);
    // Latch response
    req.rdata = vif.d_data;
    req.error = vif.d_error;
    @(posedge vif.clk);
    vif.d_ready <= 0;
    idle_bus();
  endtask

  task idle_bus();
    vif.a_valid   <= 0;
    vif.a_opcode  <= 0;
    vif.a_address <= 0;
    vif.a_data    <= 0;
    vif.a_mask    <= 4'hF;
    vif.a_source  <= 0;
    vif.a_size    <= 2'b10;
    vif.d_ready   <= 0;
  endtask

endclass
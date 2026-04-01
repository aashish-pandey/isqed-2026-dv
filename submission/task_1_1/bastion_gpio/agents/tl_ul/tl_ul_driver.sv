//=============================================================================
// tl_ul_driver.sv
// Drives flat TL-UL signals. Handles ready/valid handshake on both channels.
// Reusable across all DUTs — port names are standardized in the challenge RTL.
//=============================================================================
`ifndef TL_UL_DRIVER_SV
`define TL_UL_DRIVER_SV

class tl_ul_driver extends uvm_driver #(tl_ul_seq_item);
  `uvm_component_utils(tl_ul_driver)

  // Virtual interface handle — set via config_db in tb_top
  virtual interface tl_ul_if vif;

  // Max cycles to wait for a_ready or d_valid before flagging a timeout
  localparam int HANDSHAKE_TIMEOUT = 1000;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual tl_ul_if)::get(this, "", "tl_vif", vif))
      `uvm_fatal("NO_VIF", {"tl_ul_driver: tl_vif not found in config_db for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    idle_bus();
    // Wait for reset to deassert
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);

    forever begin
      tl_ul_seq_item req, rsp;
      seq_item_port.get_next_item(req);

      // Optional idle delay before driving
      repeat(req.delay) @(posedge vif.clk);

      drive_transaction(req, rsp);
      seq_item_port.item_done(rsp);
    end
  endtask

  // Drive one complete TL-UL transaction (A-channel then D-channel)
  task drive_transaction(tl_ul_seq_item req, output tl_ul_seq_item rsp);
    int timeout;

    rsp = tl_ul_seq_item::type_id::create("rsp");
    rsp.copy(req);

    // ── Drive Channel A ────────────────────────────────────────────────────
    vif.a_valid   <= 1'b1;
    vif.a_opcode  <= req.opcode;
    vif.a_address <= req.addr;
    vif.a_data    <= req.data;
    vif.a_mask    <= req.mask;
    vif.a_source  <= req.source;
    vif.a_size    <= req.size;
    vif.d_ready   <= 1'b1;

    // Hold A-channel until a_ready (TL-UL rule: stable while valid && !ready)
    timeout = 0;
    @(posedge vif.clk);
    while (!vif.a_ready) begin
      timeout++;
      if (timeout > HANDSHAKE_TIMEOUT)
        `uvm_fatal("TL_A_TIMEOUT",
          $sformatf("a_ready not seen within %0d cycles, addr=0x%08h", HANDSHAKE_TIMEOUT, req.addr))
      @(posedge vif.clk);
    end

    // Handshake complete — deassert valid
    vif.a_valid <= 1'b0;

    // ── Collect Channel D ──────────────────────────────────────────────────
    timeout = 0;
    while (!vif.d_valid) begin
      timeout++;
      if (timeout > HANDSHAKE_TIMEOUT)
        `uvm_fatal("TL_D_TIMEOUT",
          $sformatf("d_valid not seen within %0d cycles, addr=0x%08h", HANDSHAKE_TIMEOUT, req.addr))
      @(posedge vif.clk);
    end

    // Latch response fields into rsp
    rsp.rdata = vif.d_data;
    rsp.error = vif.d_error;

    @(posedge vif.clk);
    vif.d_ready <= 1'b0;

    idle_bus();
  endtask

  task idle_bus();
    vif.a_valid   <= 1'b0;
    vif.a_opcode  <= 3'b0;
    vif.a_address <= 32'b0;
    vif.a_data    <= 32'b0;
    vif.a_mask    <= 4'hF;
    vif.a_source  <= 8'b0;
    vif.a_size    <= 2'b10;
    vif.d_ready   <= 1'b0;
  endtask

endclass

`endif // TL_UL_DRIVER_SV

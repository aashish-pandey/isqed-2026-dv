import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_driver extends uvm_driver #(uart_seq_item);
  `uvm_component_utils(uart_driver)

  virtual uart_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif))
      `uvm_fatal("NO_VIF", "uart_driver: uart_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.uart_rx_i <= 1;  // idle high
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);
    forever begin
      uart_seq_item req;
      seq_item_port.get_next_item(req);
      drive_frame(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_frame(uart_seq_item req);
    bit parity_bit;
    int bit_period;

    // bit period = baud_div + 1 clock cycles
    bit_period = req.baud_div + 1;

    // Calculate parity
    if (req.parity_mode == 2'b01)       // even
      parity_bit = ^req.data;
    else if (req.parity_mode == 2'b10)  // odd
      parity_bit = ~(^req.data);
    else
      parity_bit = 0;

    if (req.corrupt_parity) parity_bit = ~parity_bit;

    // START bit
    vif.uart_rx_i <= 0;
    repeat(bit_period) @(posedge vif.clk);

    // DATA bits LSB first
    for (int i = 0; i < 8; i++) begin
      vif.uart_rx_i <= req.data[i];
      repeat(bit_period) @(posedge vif.clk);
    end

    // PARITY bit
    if (req.parity_mode != 2'b00) begin
      vif.uart_rx_i <= parity_bit;
      repeat(bit_period) @(posedge vif.clk);
    end

    // STOP bit(s)
    vif.uart_rx_i <= req.corrupt_stop ? 0 : 1;
    repeat(bit_period) @(posedge vif.clk);

    if (req.stop_bits) begin
      vif.uart_rx_i <= 1;
      repeat(bit_period) @(posedge vif.clk);
    end

    // Return to idle
    vif.uart_rx_i <= 1;
    repeat(4) @(posedge vif.clk);
  endtask

endclass
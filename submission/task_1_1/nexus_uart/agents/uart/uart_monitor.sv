import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)

  virtual uart_if vif;

  uvm_analysis_port #(uart_seq_item) ap_uart;

  // Configuration — must be set before run_phase
  bit [15:0] baud_div    = 8;
  bit [1:0]  parity_mode = 0;
  bit        stop_bits   = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_uart = new("ap_uart", this);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif))
      `uvm_fatal("NO_VIF", "uart_monitor: uart_vif not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    @(posedge vif.rst_n);
    repeat(2) @(posedge vif.clk);
    forever observe_frame();
  endtask

  task observe_frame();
    uart_seq_item obs;
    bit [7:0] rx_data;
    bit parity_bit;
    bit parity_exp;
    int bit_period;
    int half_period;

    bit_period  = baud_div + 1;
    half_period = bit_period / 2;

    // Wait for start bit — falling edge on uart_tx_o
    do @(posedge vif.clk);
    while (vif.uart_tx_o !== 0);

    // Move to mid-point of start bit
    repeat(half_period) @(posedge vif.clk);

    // Verify still low
    if (vif.uart_tx_o !== 0) return;

    // Sample 8 data bits at mid-point of each bit
    for (int i = 0; i < 8; i++) begin
      repeat(bit_period) @(posedge vif.clk);
      rx_data[i] = vif.uart_tx_o;
    end

    // Sample parity if enabled
    if (parity_mode != 0) begin
      repeat(bit_period) @(posedge vif.clk);
      parity_bit = vif.uart_tx_o;
    end

    // Sample stop bit
    repeat(bit_period) @(posedge vif.clk);

    // Publish transaction
    obs              = uart_seq_item::type_id::create("obs");
    obs.data         = rx_data;
    obs.baud_div     = baud_div;
    obs.parity_mode  = parity_mode;
    obs.stop_bits    = stop_bits;
    ap_uart.write(obs);

    `uvm_info("UART_MON", $sformatf("Observed TX frame: 0x%02h", rx_data), UVM_MEDIUM)
  endtask

endclass
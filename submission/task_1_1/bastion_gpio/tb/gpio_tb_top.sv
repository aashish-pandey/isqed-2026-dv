//=============================================================================
// gpio_tb_top.sv
// Top-level testbench module for bastion_gpio.
// Instantiates DUT, generates clock/reset, connects virtual interfaces,
// and kicks off the UVM test.
//=============================================================================
`ifndef GPIO_TB_TOP_SV
`define GPIO_TB_TOP_SV

module gpio_tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import dv_common_pkg::*;

  // ── Clock and reset ───────────────────────────────────────────────────────
  logic clk;
  logic rst_n;

  initial clk = 0;
  always #5 clk = ~clk;  // 100 MHz

  initial begin
    rst_n = 1'b0;
    repeat(10) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  end

  // ── TL-UL interface ───────────────────────────────────────────────────────
  tl_ul_if tl_if (.clk(clk), .rst_n(rst_n));

  // ── GPIO interface ────────────────────────────────────────────────────────
  gpio_if gpio_if_inst (.clk(clk), .rst_n(rst_n));

  // ── DUT ──────────────────────────────────────────────────────────────────
  bastion_gpio u_dut (
    .clk_i          (clk),
    .rst_ni         (rst_n),

    // TL-UL Channel A
    .tl_a_valid_i   (tl_if.a_valid),
    .tl_a_ready_o   (tl_if.a_ready),
    .tl_a_opcode_i  (tl_if.a_opcode),
    .tl_a_address_i (tl_if.a_address),
    .tl_a_data_i    (tl_if.a_data),
    .tl_a_mask_i    (tl_if.a_mask),
    .tl_a_source_i  (tl_if.a_source),
    .tl_a_size_i    (tl_if.a_size),

    // TL-UL Channel D
    .tl_d_valid_o   (tl_if.d_valid),
    .tl_d_ready_i   (tl_if.d_ready),
    .tl_d_opcode_o  (tl_if.d_opcode),
    .tl_d_data_o    (tl_if.d_data),
    .tl_d_source_o  (tl_if.d_source),
    .tl_d_error_o   (tl_if.d_error),

    // GPIO pins
    .gpio_i         (gpio_if_inst.gpio_i),
    .gpio_o         (gpio_if_inst.gpio_o),
    .gpio_oe_o      (gpio_if_inst.gpio_oe_o),
    .intr_o         (gpio_if_inst.intr_o),
    .alert_o        (gpio_if_inst.alert_o)
  );

  // ── Register interfaces in config_db ─────────────────────────────────────
  initial begin
    // TL-UL virtual interface — used by driver and monitor
    uvm_config_db #(virtual tl_ul_if)::set(
      null, "uvm_test_top.*", "tl_vif", tl_if);

    // GPIO virtual interface — used by gpio_driver, gpio_monitor, scoreboard
    uvm_config_db #(virtual gpio_if)::set(
      null, "uvm_test_top.*", "gpio_vif", gpio_if_inst);

    // Launch the UVM test (name supplied via +UVM_TESTNAME on command line)
    run_test();
  end

  // ── Simulation timeout guard ──────────────────────────────────────────────
  initial begin
    #2_000_000;
    `uvm_fatal("TB_TIMEOUT", "Simulation exceeded 2ms — check for hangs")
  end

endmodule

//=============================================================================
// gpio_if — GPIO pin interface
//=============================================================================
interface gpio_if (input logic clk, input logic rst_n);

  logic [31:0] gpio_i;    // driven by gpio_driver / test
  logic [31:0] gpio_o;    // sampled from DUT
  logic [31:0] gpio_oe_o; // sampled from DUT
  logic [31:0] intr_o;    // sampled from DUT
  logic        alert_o;   // sampled from DUT

  // Initialize inputs to safe state
  initial begin
    gpio_i = 32'h0;
  end

endinterface

`endif // GPIO_TB_TOP_SV

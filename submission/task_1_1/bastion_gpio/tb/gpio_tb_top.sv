import uvm_pkg::*;
`include "uvm_macros.svh"

module gpio_tb_top;

  import dv_common_pkg::*;

  logic clk;
  logic rst_n;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    repeat(10) @(posedge clk);
    @(negedge clk);
    rst_n = 1;
  end

  // Interface instances
  tl_ul_if tl_if (.clk(clk), .rst_n(rst_n));
  gpio_if  gpio_if_inst (.clk(clk), .rst_n(rst_n));

  // DUT
  bastion_gpio u_dut (
    .clk_i          (clk),
    .rst_ni         (rst_n),
    .tl_a_valid_i   (tl_if.a_valid),
    .tl_a_ready_o   (tl_if.a_ready),
    .tl_a_opcode_i  (tl_if.a_opcode),
    .tl_a_address_i (tl_if.a_address),
    .tl_a_data_i    (tl_if.a_data),
    .tl_a_mask_i    (tl_if.a_mask),
    .tl_a_source_i  (tl_if.a_source),
    .tl_a_size_i    (tl_if.a_size),
    .tl_d_valid_o   (tl_if.d_valid),
    .tl_d_ready_i   (tl_if.d_ready),
    .tl_d_opcode_o  (tl_if.d_opcode),
    .tl_d_data_o    (tl_if.d_data),
    .tl_d_source_o  (tl_if.d_source),
    .tl_d_error_o   (tl_if.d_error),
    .gpio_i         (gpio_if_inst.gpio_i),
    .gpio_o         (gpio_if_inst.gpio_o),
    .gpio_oe_o      (gpio_if_inst.gpio_oe_o),
    .intr_o         (gpio_if_inst.intr_o),
    .alert_o        (gpio_if_inst.alert_o)
  );

  // Register interfaces in config_db and start test
  initial begin
    uvm_config_db #(virtual tl_ul_if)::set(null, "uvm_test_top.*", "tl_vif",   tl_if);
    uvm_config_db #(virtual gpio_if)::set(null,  "uvm_test_top.*", "gpio_vif", gpio_if_inst);
    run_test();
  end

  // Timeout
  initial begin
    #1_000_000;
    $fatal(1, "TIMEOUT: simulation exceeded 1ms");
  end

endmodule
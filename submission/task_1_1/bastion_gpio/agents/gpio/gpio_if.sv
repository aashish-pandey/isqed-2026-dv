interface gpio_if (input logic clk, input logic rst_n);

  logic [31:0] gpio_i;
  logic [31:0] gpio_o;
  logic [31:0] gpio_oe_o;
  logic [31:0] intr_o;
  logic        alert_o;

  initial begin
    gpio_i = 32'h0;
  end

endinterface
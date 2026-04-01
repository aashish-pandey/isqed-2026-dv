interface uart_if (input logic clk, input logic rst_n);

  logic uart_rx_i;
  logic uart_tx_o;
  logic [6:0] intr_o;
  logic alert_o;

  initial begin
    uart_rx_i = 1;
  end

endinterface
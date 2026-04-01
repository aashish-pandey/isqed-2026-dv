interface tl_ul_if (input logic clk, input logic rst_n);

  logic        a_valid;
  logic        a_ready;
  logic [2:0]  a_opcode;
  logic [31:0] a_address;
  logic [31:0] a_data;
  logic [3:0]  a_mask;
  logic [7:0]  a_source;
  logic [1:0]  a_size;

  logic        d_valid;
  logic        d_ready;
  logic [2:0]  d_opcode;
  logic [31:0] d_data;
  logic [7:0]  d_source;
  logic        d_error;

endinterface
module CORE(
  clk,
  rst_n,
  in_valid,
  in_mode,
  in_data_1,
  in_data_2,
  out_valid,
  out_data
);
input               clk;
input               rst_n;
input               in_valid;
input               in_mode;
input       [9:0]   in_data_1;
input       [2:0]   in_data_2;
output reg          out_valid;
output reg  [19:0]  out_data;

endmodule 
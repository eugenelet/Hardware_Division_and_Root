`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
  `include "CORE.v"
`endif

`ifdef GATE
  `include "CORE_syn.v"
`endif

module TESTBENCH();
initial begin
  `ifdef GATE
    $sdf_annotate("CORE_syn.sdf",u_core);
  `endif
  
  `ifdef FSDB
    $fsdbDumpfile("CORE.fsdb");
    $fsdbDumpvars;
  `endif
end

wire          clk;
wire          rst_n;
wire          in_valid;
wire          in_mode;
wire  [9:0]   in_data_1;
wire  [2:0]   in_data_2;
wire          out_valid;
wire  [19:0]  out_data; // MSB 10-bit is the integer part, LSB 10-bit is the fractional part
PATTERN u_pattern(
  clk,
  rst_n,
  in_valid,
  in_mode,
  in_data_1,
  in_data_2,
  out_valid,
  out_data
);
CORE u_core(
  clk,
  rst_n,
  in_valid,
  in_mode,
  in_data_1,
  in_data_2,
  out_valid,
  out_data
);
endmodule 

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
input               in_mode;// 0 = Division; 1 = Root
input       [9:0]   in_data_1;
input       [2:0]   in_data_2;
output reg          out_valid;
output reg  [19:0]  out_data;

wire        [19:0]  out_div;
wire        [19:0]  out_root;
wire                out_valid_div;
wire                out_valid_root;

Division div(
    .clk         (clk),
    .rst_n       (rst_n),
    .in_valid    (in_valid),
    .in_data_1   (in_data_1),
    .in_data_2   (in_data_2),
    .out_valid   (out_valid_div),
    .out_data    (out_div)
);


Root rt(
    .clk         (clk),
    .rst_n       (rst_n),
    .in_valid    (in_valid),
    .in_data_1   (in_data_1),
    .in_data_2   (in_data_2),
    .out_valid   (out_valid_root),
    .out_data    (out_root)
);

always @(posedge clk) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
        out_data <= 'd0;        
    end
    else if (out_valid_div && !in_mode) begin
        out_valid <= out_valid_div;
        out_data <= out_div;
    end
    else if(out_valid_root && in_mode) begin
        out_valid <= out_valid_root;
        out_data <= out_root;
    end
    else begin
        out_valid <= 1'b0;
    end
end

endmodule 
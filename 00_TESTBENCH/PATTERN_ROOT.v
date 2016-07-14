`ifdef RTL
  `define CLK_PERIOD  5
`endif

`ifdef GATE
  `define CLK_PERIOD  5.1
`endif

`define PATTERN_NUM 100
`define MAX_LATENCY 1000

module PATTERN(
  clk,
  rst_n,
  in_valid,
  in_mode,
  in_data_1,
  in_data_2,
  out_valid,
  out_data
);
output  reg         clk;
output  reg         rst_n;
output  reg         in_valid;
output  reg         in_mode;
output  reg [9:0]   in_data_1;
output  reg [2:0]   in_data_2;
input               out_valid;
input       [19:0]  out_data;

initial clk = 0;
always #(`CLK_PERIOD/2) clk = ~clk;

initial begin
  rst_n = 1;
  @(negedge clk);
  @(negedge clk);
  @(negedge clk);
  rst_n = 0;
  @(negedge clk);
  rst_n = 1;
end

integer             in_data_2_tmp;
integer             pattern_idx,data_idx;
integer             latency_max,latency;
reg                 done;
real                golden_ans;
real                user_ans,user_ans_tmp;
integer             user_ans_idx;
real                delta_max,delta;
initial begin
  in_valid    = 'd0;
  in_mode     = 'd0;
  in_data_1   = 'd0;
  in_data_2   = 'd0;
  latency_max = 'd0;
  delta_max   = 'd0;
  repeat(6) @(negedge clk);
  $display("");
  $display("========================================");
  $display("| n-th Root Mode                       |");
  $display("========================================");
  $display("");
  for(pattern_idx=0;pattern_idx<`PATTERN_NUM;pattern_idx=pattern_idx+1) begin
    in_mode = 1;
  
    $display("");
    $display("PATTERN NO. %3d", pattern_idx);
    // test pattern in
    @(negedge clk);
    in_valid  = 'd1;
    in_data_1 = $random();
    for(in_data_2 = ($random()%7)+1;in_data_2=='d0;in_data_2 = ($random()%7)+1) begin end
    @(negedge clk);
    in_valid  = 0;
    done      = 0;
    // wait for out_valid rising
    for(latency=0;latency<`MAX_LATENCY && done==0;latency=latency+1) begin
      @(negedge clk);
      if(out_valid)
        done  = 1;
    end
    if(latency==`MAX_LATENCY) begin
      $display("calculating time is more then %d cycles",`MAX_LATENCY);
      $finish;
    end
    else if(latency>latency_max)
      latency_max=latency;
    // calculate delta
    user_ans_tmp  = Binary2Real_20(out_data);
    user_ans      = user_ans_tmp;
    for(user_ans_idx=1;user_ans_idx<in_data_2;user_ans_idx=user_ans_idx+1) begin
      if(in_mode==0)
        user_ans  = user_ans+user_ans_tmp;
      else
        user_ans  = user_ans*user_ans_tmp;
    end
    golden_ans  = Binary2Real_10(in_data_1);
    delta       = AbsoluteDifference(user_ans,golden_ans);
    $display("golden_ans: %f", golden_ans);
    $display("user_ans: %f", user_ans);

    if(in_mode==0)
      $display("%d/%d=%f",in_data_1,in_data_2,user_ans_tmp);
    else
      $display("%d^(1/%d)=%f",in_data_1,in_data_2,user_ans_tmp);
    $display("delta is %f",delta);
    if(delta>delta_max)
      delta_max=delta;
  end
  $display("");
  $display("========================================");
  $display(" MAX_DELTA    = %f",delta_max);
  $display(" MAX_LATENCY  = %4d",latency_max);
  $display("========================================");
  $display("");
  
  @(negedge clk);
  $finish;
end

function real Binary2Real_20;
  input   [19:0]  data;
  real            bias;
  integer         bias_idx;
  begin   
    Binary2Real_20  = 0;
    bias            = 512;  
    for(bias_idx=19;bias_idx>=0;bias_idx=bias_idx-1) begin
      Binary2Real_20  = Binary2Real_20+data[bias_idx]*bias;
      bias            = bias/2;
    end
  end
endfunction

function real Binary2Real_10;
  input   [9:0]   data;
  real            bias;
  integer         bias_idx;
  begin   
    Binary2Real_10  = 0;
    bias            = 512;  
    for(bias_idx=9;bias_idx>=0;bias_idx=bias_idx-1) begin
      Binary2Real_10  = Binary2Real_10+data[bias_idx]*bias;
      bias            = bias/2;
    end
  end
endfunction

function real AbsoluteDifference;
  input real  data1;
  input real  data2;
  begin
    AbsoluteDifference  = data1-data2;
    if(AbsoluteDifference<=0)
      AbsoluteDifference=AbsoluteDifference*-1;
  end
endfunction
endmodule 

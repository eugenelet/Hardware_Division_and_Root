module Division(
    clk,
    rst_n,
    in_valid,
    in_data_1,
    in_data_2,
    out_valid,
    out_data
);

parameter	INIT_STATE	= 'd0;
parameter	STORE_INPUT	= 'd1;
parameter	DIVIDE 		= 'd2;
parameter	DUMP_OUTPUT = 'd3;


parameter	BASE = 22'h200000;

input				clk;
input				rst_n;
input				in_valid;
input		[9:0]	in_data_1;
input		[2:0]	in_data_2;
output reg			out_valid;
output reg	[19:0]	out_data;

reg			[1:0]	current_state;
reg			[1:0]	next_state;


/*
 *	Take input
 *
 */
reg			[22:0]	dividend;
always @(posedge clk) begin
	if (!rst_n) begin
		dividend <= 'd0;		
	end
	else if (current_state == STORE_INPUT) begin
		dividend <= {in_data_1, {12'b0}};
	end
	else if (current_state == INIT_STATE) begin
		dividend <= 'd0;
	end
end


/*
 *	Compute Division
 *
 */
reg			[22:0]	dividend_match;
reg			[22:0]	current_base;
reg			[22:0]	out_extend;
wire		[22:0]	guess_result = dividend_match | current_base;
reg					terminate_flag;
always @(posedge clk) begin
	if (!rst_n) begin
		dividend_match <= 'd0;		
		current_base <= BASE;
		out_extend <= 'd0;
		terminate_flag <= 1'b0;
	end
	else if (current_state==DIVIDE && current_base=='d0) begin // all iteration done
		terminate_flag <= 1'b1;
	end
	else if (current_state == DIVIDE) begin
		current_base <= current_base >> 1'b1;
		if(guess_result < dividend) begin //correct guess
			dividend_match <= guess_result;
			out_extend <= out_extend | current_base;
		end
		else if (guess_result == dividend) begin// exact match!
			dividend_match <= guess_result;
			out_extend <= out_extend | current_base;
			terminate_flag <= 1'b1;
		end
		else begin // wrong guess, don't take result
			//dividend_match <= dividend_match; dont have to do anything
		end
	end
	else if (current_state == INIT_STATE) begin
		dividend_match <= 'd0;
		current_base <= BASE;
		terminate_flag <= 1'b0;
	end
end


/*
 *	Dump Output
 *
 */
always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 'd0;	
		out_valid <= 1'b0;
	end
	else if (current_state == DUMP_OUTPUT) begin
		out_data <= out_extend[22:2];
		out_valid <= 1'b1;
	end
	else if (current_state == INIT_STATE) begin
		out_valid <= 1'b0;
	end
end

/*
 *	Finite State Machine
 *
 */

always @(posedge clk) begin
	if (!rst_n) begin
		current_state <= INIT_STATE;
		next_state <= 'd0;
	end
	else begin
		current_state <= next_state;
	end
end

always @(*) begin
	case(current_state)
		INIT_STATE: begin
			if(in_valid) begin
				next_state = STORE_INPUT;
			end
			else begin
				next_state = current_state;
			end
		end
		STORE_INPUT: begin
			if(!in_valid) begin
				next_state = DIVIDE;
			end
			else begin
				next_state = current_state;
			end
		end
		DIVIDE: begin
			if (terminate_flag) begin
				next_state = DUMP_OUTPUT;
			end
			else begin
				next_state = current_state;
			end
		end
		DUMP_OUTPUT: begin
			if (out_data == out_extend[22:2]) begin
				next_state = INIT_STATE;
			end
			else begin
				next_state = current_state;
			end
		end
	endcase
end

endmodule
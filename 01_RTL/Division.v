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


parameter	BASE = 20'h20000; //18th bit

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
reg			[21:0]	dividend;
always @(posedge clk) begin
	if (!rst_n) begin
		dividend <= 'd0;		
	end
	else if (current_state == STORE_INPUT) begin
		dividend <= {1'b0, in_data_1, {10'b0}};
	end
	else if (current_state == INIT_STATE) begin
		dividend <= 'd0;
	end
end


/*
 *	Compute Division
 *
 */
//reg			[22:0]	out_extend;
reg			[20:0]	current_base;
wire		[21:0]	guess_result = (out_data | current_base) * in_data_2;
reg					terminate_flag;
always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 'd0;		
		current_base <= BASE;
		terminate_flag <= 1'b0;
	end
	else if (current_state==DIVIDE && current_base=='d0) begin // all iteration done
		terminate_flag <= 1'b1;
	end
	else if (current_state == DIVIDE) begin
		current_base <= current_base >> 1'b1;
		if(guess_result < dividend) begin //correct guess
			out_data <= out_data | current_base;
		end
		else if (guess_result == dividend) begin// exact match!
			out_data <= out_data | current_base;
			terminate_flag <= 1'b1;
		end
		else begin // wrong guess, don't take result
			out_data <= out_data;
		end
	end
	else if (current_state == INIT_STATE) begin
		out_data <= 'd0;
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
			if (out_valid) begin
				next_state = INIT_STATE;
			end
			else begin
				next_state = current_state;
			end
		end
	endcase
end

endmodule
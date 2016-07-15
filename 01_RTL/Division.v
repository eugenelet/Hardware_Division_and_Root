module Division(
    clk,
    rst_n,
    in_valid,
    in_data_1,
    in_data_2,
    out_valid,
    out_data
);

parameter	ST_INIT		= 'd0;
parameter	ST_STORE	= 'd1;
parameter	ST_DIVIDE 	= 'd2;
parameter	ST_OUTPUT 	= 'd3;


parameter	BASE = 20'h80000; //19th bit

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
reg			[21:0]	ST_DIVIDEnd;
always @(posedge clk) begin
	if (!rst_n) begin
		ST_DIVIDEnd <= 'd0;		
	end
	else if (current_state == ST_STORE) begin
		ST_DIVIDEnd <= {1'b0, in_data_1, {10'b0}};
	end
	else if (current_state == ST_INIT) begin
		ST_DIVIDEnd <= 'd0;
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
	else if (current_state==ST_DIVIDE && current_base=='d0) begin // all iteration done
		terminate_flag <= 1'b1;
	end
	else if (current_state == ST_DIVIDE) begin
		current_base <= current_base >> 1'b1;
		if(guess_result < ST_DIVIDEnd) begin //correct guess
			out_data <= out_data | current_base;
		end
		else if (guess_result == ST_DIVIDEnd) begin// exact match!
			out_data <= out_data | current_base;
			terminate_flag <= 1'b1;
		end
		else begin // wrong guess, don't take result
			out_data <= out_data;
		end
	end
	else if (current_state == ST_INIT) begin
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
	else if (current_state == ST_OUTPUT) begin
		out_valid <= 1'b1;
	end
	else if (current_state == ST_INIT) begin
		out_valid <= 1'b0;
	end
end

/*
 *	Finite State Machine
 *
 */

always @(posedge clk) begin
	if (!rst_n) begin
		current_state <= ST_INIT;
		next_state <= 'd0;
	end
	else begin
		current_state <= next_state;
	end
end

always @(*) begin
	case(current_state)
		ST_INIT: begin
			if(in_valid) begin
				next_state = ST_STORE;
			end
			else begin
				next_state = current_state;
			end
		end
		ST_STORE: begin
			if(!in_valid) begin
				next_state = ST_DIVIDE;
			end
			else begin
				next_state = current_state;
			end
		end
		ST_DIVIDE: begin
			if (terminate_flag) begin
				next_state = ST_OUTPUT;
			end
			else begin
				next_state = current_state;
			end
		end
		ST_OUTPUT: begin
			if (out_valid) begin
				next_state = ST_INIT;
			end
			else begin
				next_state = current_state;
			end
		end
	endcase
end

endmodule
module Root(
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
parameter	ST_COMPUTE	= 'd2;
parameter	ST_OUTPUT 	= 'd3;


parameter	BASE = 20'h80000; //20th bit

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
reg			[139:0]	pow_result;
always @(posedge clk) begin
	if (!rst_n) begin
		pow_result <= 'd0;		
	end
	else if (current_state == ST_STORE) begin
		pow_result <= {in_data_1, {130'b0}};
	end
	else if (current_state == ST_INIT) begin
		pow_result <= 'd0;
	end
end


/*
 *	Compute Root
 *
 */
reg			[19:0]	current_base;
//wire		[139:0]	debug_guess = (out_data | current_base) ** in_data_2;
reg			[139:0]	guess_result;// = ((out_data | current_base) ** in_data_2);// << (5-in_data_2)*10;
reg			[139:0]	pow_result_shift;// = pow_result >> (in_data_2-1)*10;
reg					terminate_flag;
reg			[139:0] exponent_result;


/*
 *	Compute Exponent
 *
 */
always @(*) begin
	case(in_data_2)
	'd0: begin
		exponent_result = 'd1;
	end
	'd1: begin
		exponent_result = (out_data|current_base);
	end
	'd2: begin
		exponent_result = (out_data|current_base) * (out_data|current_base);
	end
	'd3: begin
		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base);
	end
	'd4: begin
		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base);
	end
	'd5: begin
		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
							(out_data|current_base);
	end
	'd6: begin
		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
							(out_data|current_base) * (out_data|current_base);
	end
	'd7: begin
		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
							(out_data|current_base) * (out_data|current_base) * (out_data|current_base);
	end
	default: exponent_result = 'd0;
	endcase
end

always @(*) begin
	guess_result = exponent_result << ((7-in_data_2)*20);
	pow_result_shift = pow_result >> (in_data_2-1)*10;
end



always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 'd0;		
		current_base <= BASE;
		terminate_flag <= 1'b0;
	end
	else if (current_state==ST_COMPUTE && current_base=='d0) begin // all iteration done
		terminate_flag <= 1'b1;
	end
	else if (current_state == ST_COMPUTE) begin
		current_base <= current_base >> 1'b1;
		if(guess_result < pow_result_shift) begin //correct guess
			out_data <= out_data | current_base;
		end
		else if (guess_result == pow_result_shift) begin// exact match!
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
		//out_data <= 'd0;	
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
	end
	else begin
		current_state <= next_state;
	end
end

always @(*) begin
	if (!rst_n) begin
		next_state = 'd0;
	end
	else begin
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
					next_state = ST_COMPUTE;
				end
				else begin
					next_state = current_state;
				end
			end
			ST_COMPUTE: begin
				//if (ST_COMPUTE_fail) begin
				//	next_state = COMPUTE_POW;
				//end
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
	
end

endmodule
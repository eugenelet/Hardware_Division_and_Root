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
parameter	ST_COMPARE	= 'd1;
parameter	ST_POW		= 'd2;
parameter	ST_OUTPUT 	= 'd3;


parameter	BASE = 20'h4000; //15th bit

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
 *	Compute Root
 *
 */
reg			[19:0]	current_base;
//reg			[139:0]	guess_result;// = ((out_data | current_base) ** in_data_2);// << (5-in_data_2)*10;
//reg			[139:0]	pow_result_shift;// = pow_result >> (in_data_2-1)*10;
//reg			[139:0] exponent_result;

wire		[19:0]	extended_in = {in_data_1, {10'b0}};
/*
 *	Compute Exponent
 *
 */
//always @(*) begin
//	case(in_data_2)
//	'd0: begin
//		exponent_result = 'd1;
//	end
//	'd1: begin
//		exponent_result = (out_data|current_base);
//	end
//	'd2: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base);
//	end
//	'd3: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base);
//	end
//	'd4: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base);
//	end
//	'd5: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
//							(out_data|current_base);
//	end
//	'd6: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
//							(out_data|current_base) * (out_data|current_base);
//	end
//	'd7: begin
//		exponent_result = (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * (out_data|current_base) * 
//							(out_data|current_base) * (out_data|current_base) * (out_data|current_base);
//	end
//	default: exponent_result = 'd0;
//	endcase
//end
//
//always @(*) begin
//	guess_result = exponent_result << ((7-in_data_2)*20);
//	pow_result_shift = pow_result >> (in_data_2-1)*10;//use mux manually
//end

/*
 *	Compute Power
 *
 */

reg		[2:0]	pow_count;
always @(posedge clk) begin
	if (!rst_n) begin
		pow_count <= 'd0;		
	end
	else if (current_state == ST_POW) begin
		pow_count <= pow_count + 1'b1;
	end
	else begin
		pow_count <= 'd0;
	end
end

reg		[19:0]	current_guess;
reg		[19:0]	guess_result;
reg		[19:0]	pow_result;
wire 	[39:0] 	extended_pow = pow_result * (current_guess);//Q10.10 * Q10.10
always @(posedge clk) begin
	if (!rst_n) begin
		pow_result <= current_guess;		
	end
	else if (current_state==ST_POW && pow_count<in_data_2) begin
		pow_result <= extended_pow >> 'd10;
	end
	else begin
		pow_result <= guess_result | current_base;
	end
end

reg			  compute_done;
always @(posedge clk) begin
	if (!rst_n) begin
		compute_done <= 1'b0;		
	end
	else if (current_state==ST_POW && (pow_count + 1) == in_data_2) begin
		compute_done <= 1'b1;
	end
	else begin
		compute_done <= 1'b0;
	end
end


//wire		[19:0]	shift_pow_result = pow_result >> 5;//only 5 bits will be fixed bits

/*
 *	Compare Result of Power Computation
 *
 */
always @(posedge clk) begin
	if (!rst_n) begin
		guess_result <= 'd0;		
	end
	else if (current_state==ST_COMPARE && in_data_2=='d1) begin//pow 1
		guess_result <= extended_in;
	end
	else if (current_state==ST_COMPARE && (pow_result<extended_in || pow_result==extended_in) ) begin
		guess_result <= current_guess;
	end
	else if (current_state == ST_INIT) begin
		guess_result <= 'd0;
	end
end


always @(posedge clk) begin
	if (!rst_n) begin
		current_guess <= 'd0;
	end
	else if (current_state == ST_COMPARE) begin
		current_guess <= guess_result | current_base;
	end
	else if (current_state == ST_INIT) begin
		current_guess <= 'd0;
	end
end


always @(posedge clk) begin
	if (!rst_n) begin
		current_base <= BASE;
	end
	else if (current_state == ST_COMPARE) begin
		current_base <= current_base >> 1'b1;
	end
	else if (current_state == ST_INIT) begin
		current_base <= BASE;
	end
end

reg					terminate_flag;
always @(posedge clk) begin
	if (!rst_n) begin
		terminate_flag <= 1'b0;
	end
	else if (current_state==ST_COMPARE && (current_base=='d0 || pow_result==extended_in || in_data_2=='d1) ) begin 
	// all iteration done OR exact match OR raised to POW 1 (no computation needed)
		terminate_flag <= 1'b1;
	end
	else if (current_state == ST_INIT) begin
		terminate_flag <= 1'b0;
	end
end



/*
 *	Dump Output
 *
 */
always @(posedge clk) begin
	if (!rst_n) begin
		out_valid <= 1'b0;
	end
	else if (current_state == ST_OUTPUT) begin
		out_valid <= 1'b1;
	end
	else begin
		out_valid <= 1'b0;
	end
end


always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 1'b0;
	end
	else if (current_state == ST_OUTPUT) begin
		out_data <= guess_result;
	end
	else begin
		out_data <= 1'b0;
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
					next_state = ST_COMPARE;
				end
				else begin
					next_state = ST_INIT;
				end
			end
			ST_COMPARE: begin
				if (terminate_flag) begin
					next_state = ST_OUTPUT;
				end
				else begin
					next_state = ST_POW;
				end
			end
			ST_POW: begin
				if (compute_done) begin
					next_state = ST_COMPARE;
				end
				else begin
					next_state = ST_POW;
				end
			end
			ST_OUTPUT: begin
				if (out_valid) begin
					next_state = ST_INIT;
				end
				else begin
					next_state = ST_OUTPUT;
				end
			end
		endcase	
	end
	
end

endmodule
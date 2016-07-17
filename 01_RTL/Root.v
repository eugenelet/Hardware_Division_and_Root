module Root(
    clk,
    rst_n,
    in_valid,
    in_data_1,
    in_data_2,
    out_valid,
    out_data
);

parameter	ST_IDLE		= 'd0;
parameter	ST_COMPARE	= 'd1;
parameter	ST_POW		= 'd2;
parameter	ST_OUTPUT 	= 'd3;


parameter	BASE = 20'h04000; //15th bit

input				clk;
input				rst_n;
input				in_valid;
input		[9:0]	in_data_1;
input		[2:0]	in_data_2;
output reg			out_valid;
output reg	[19:0]	out_data;

reg			[1:0]	current_state;
reg			[1:0]	next_state;

reg			[19:0]	current_base;
wire		[19:0]	extended_in = {in_data_1, {10'b0}};//for comparing purpose


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
//reg		[19:0]	out_data;
reg		[19:0]	pow_result;
wire 	[39:0] 	extended_pow = pow_result * (current_guess);//Q10.10 * Q10.10
always @(posedge clk) begin
	if (!rst_n) begin
		pow_result <= current_guess;		
	end
	else if (current_state==ST_POW && extended_pow>{ {10'b0}, extended_in, {10'b0} } && pow_count<(in_data_2-1)) begin
		pow_result <= 20'hfffff;
	end
	else if (current_state==ST_POW && pow_count<(in_data_2-1)) begin
		pow_result <= extended_pow >> 'd10;
	end

	//Initialize before compute
	else if (current_state==ST_COMPARE && pow_result<extended_in) begin
		pow_result <= current_guess | current_base;
	end
	else if (current_state==ST_COMPARE) begin
		pow_result <= out_data | current_base;
	end
end

//Terminate ST_POW
reg			  compute_done;
always @(posedge clk) begin
	if (!rst_n) begin
		compute_done <= 1'b0;		
	end
	else if (current_state==ST_POW && ((pow_count + 1)==in_data_2 || extended_pow>{ {10'b0}, extended_in, {10'b0} }) ) begin
	//Saves a cycle by ending right at the last POW
		compute_done <= 1'b1;
	end
	else begin
		compute_done <= 1'b0;
	end
end


/*
 *	Compare Result of Power Computation
 *
 */
always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 'd0;		
	end

	//Terminate Early if no POW needed
	else if (current_state==ST_COMPARE && in_data_2=='d1) begin
		out_data <= extended_in;
	end

	//Update out_data (correct guess!)
	else if (current_state==ST_COMPARE && (pow_result<extended_in || pow_result==extended_in) ) begin
		out_data <= current_guess;
	end

	//IDLE
	else if (current_state == ST_IDLE) begin
		out_data <= 'd0;
	end
end


always @(posedge clk) begin
	if (!rst_n) begin
		current_guess <= 'd0;
	end
	//Update current_guess based on previous guess
	else if (current_state==ST_COMPARE && pow_result<extended_in) begin
		current_guess <= current_guess | current_base;
	end
	//Update current guess based on previous CORRECT guess
	else if (current_state==ST_COMPARE) begin
		current_guess <= out_data | current_base;
	end
	//IDLE
	else if (current_state == ST_IDLE) begin
		current_guess <= 'd0;
	end
end


always @(posedge clk) begin
	if (!rst_n) begin
		current_base <= BASE;
	end
	//Shifting of Base
	else if (current_state == ST_COMPARE) begin
		current_base <= current_base >> 1'b1;
	end
	//IDLE
	else if (current_state == ST_IDLE) begin
		current_base <= BASE;
	end
end

//Terminate ST_COMPARE -> ST_OUTPUT
reg					terminate_flag;
always @(posedge clk) begin
	if (!rst_n) begin
		terminate_flag <= 1'b0;
	end
	else if (current_state==ST_COMPARE && (current_base=='d0 || pow_result==extended_in || in_data_2=='d1) ) begin 
	// all iteration done OR exact match OR raised to POW 1 (no computation needed)
		terminate_flag <= 1'b1;
	end
	else if (current_state == ST_IDLE) begin
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


//always @(posedge clk) begin
//	if (!rst_n) begin
//		out_data <= 1'b0;
//	end
//	else if (current_state == ST_OUTPUT) begin
//		out_data <= out_data;
//	end
//	else begin
//		out_data <= 1'b0;
//	end
//end

/*
 *	Finite State Machine
 *
 */

always @(posedge clk) begin
	if (!rst_n) begin
		current_state <= ST_IDLE;
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
			ST_IDLE: begin
				if(in_valid) begin
					next_state = ST_COMPARE;
				end
				else begin
					next_state = ST_IDLE;
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
					next_state = ST_IDLE;
				end
				else begin
					next_state = ST_OUTPUT;
				end
			end
		endcase	
	end
	
end

endmodule
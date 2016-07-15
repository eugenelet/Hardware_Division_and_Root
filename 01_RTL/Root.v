module Root(
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
parameter	COMPARE		= 'd2;
//parameter	COMPUTE_POW	= 'd3;
parameter	DUMP_OUTPUT = 'd3;


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
reg			[59:0]	pow_result;
always @(posedge clk) begin
	if (!rst_n) begin
		pow_result <= 'd0;		
	end
	else if (current_state == STORE_INPUT) begin
		pow_result <= {in_data_1, {50'b0}};
	end
	else if (current_state == INIT_STATE) begin
		pow_result <= 'd0;
	end
end


/*
 *	Compute Root
 *
 */
//reg			[22:0]	out_extend;
reg			[19:0]	current_base;
wire		[59:0]	debug_guess = (out_data | current_base) ** in_data_2;
reg			[59:0]	guess_result_temp;
reg			[59:0]	guess_result_temp2;
reg			[59:0]	guess_result;// = ((out_data | current_base) ** in_data_2);// << (5-in_data_2)*10;
reg			[59:0]	pow_result_shift;// = pow_result >> (in_data_2-1)*10;
reg					terminate_flag;

always @(*) begin
	if (in_data_2 < 4) begin
		guess_result = ( (out_data|current_base) ** in_data_2 ) << ((3-in_data_2)*20);//Q10.50
		pow_result_shift = pow_result;
	end
	else if (in_data_2 < 7) begin
		guess_result_temp = ( (out_data|current_base) ** 3 );//Q10.50
		guess_result = ( (guess_result_temp >> 40) * ( ((out_data|current_base)**(in_data_2-3)) >> (in_data_2-4)*20) ) << 20;
		pow_result_shift = pow_result >> 10;
		//(Q10.10 * Q10.10) << 20
	end
	else begin
		guess_result_temp = ( (out_data|current_base) ** 3 );//Q10.50
		guess_result_temp2 = ( (guess_result_temp >> 40) * ( ((out_data|current_base)**3) >> 40) ) >> 10;
		//Q10.10 * Q10.10 = Q20.20 >> 10 =Q20.10
		guess_result = guess_result_temp2 * (out_data | current_base) ;
		pow_result_shift = pow_result >> 20;
		
	end
end

always @(posedge clk) begin
	if (!rst_n) begin
		out_data <= 'd0;		
		current_base <= BASE;
		terminate_flag <= 1'b0;
	end
	else if (current_state==COMPARE && current_base=='d0) begin // all iteration done
		terminate_flag <= 1'b1;
	end
	else if (current_state == COMPARE) begin
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
				next_state = COMPARE;
			end
			else begin
				next_state = current_state;
			end
		end
		COMPARE: begin
			//if (compare_fail) begin
			//	next_state = COMPUTE_POW;
			//end
			if (terminate_flag) begin
				next_state = DUMP_OUTPUT;
			end
			else begin
				next_state = current_state;
			end
		end
		//COMPUTE_POW: begin
		//	if(compute_done) begin
		//		next_state = COMPARE;
		//	end
		//	else begin
		//		next_state = current_state;
		//	end
		//end
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
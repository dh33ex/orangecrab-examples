module sense(
	input				clk,
	input				rst,
	input				sense_lvds,
	input				sense_go,

	output				sense_fb,
	output reg	[14:0]	sense_res,
	output				sense_rdy
);
	// FSM
	parameter S_IDLE		= 2'd0;
	parameter S_SETUP		= 2'd1;
	parameter S_CHARGE		= 2'd2;
	parameter S_DISCHARGE	= 2'd3;

	reg [1:0] current_state;
	reg [1:0] next_state;

	// Timer
	reg [15:0] timer, timer_max;
	wire timer_trig;

	// Measurement counter
	reg [14:0] sense_cnt;



	//-----------------
	// Timer
	//-----------------
	always @(posedge clk) begin: STATE_TIMER
		if (timer_trig)
			timer <= 16'd0;
		else
			timer <= timer + 1'd1;
	end

	// all timer_max values calculated for 48MHz clock
	assign timer_trig = (timer == timer_max);



	//-----------------
	// FSM
	//-----------------

	// State memory
	always @(posedge clk) begin: STATE_MEMORY
		if (rst)
			current_state <= S_IDLE;
		else
			current_state <= next_state;
	end

	// Next state logic
	always @(*) begin: NEXT_STATE_LOGIC
		next_state = current_state;

		case (current_state)
			S_IDLE		: if (sense_go)		next_state = S_SETUP;
			S_SETUP		: if (timer_trig)	next_state = S_CHARGE;
			S_CHARGE	: if (timer_trig)	next_state = S_DISCHARGE;
			S_DISCHARGE	: if (timer_trig)	next_state = S_IDLE;
			default		: 					next_state = 2'bxx;
		endcase
	end

	// Output logic
	always @(*) begin: OUTPUT_LOGIC
		case (current_state)
			S_IDLE: begin
				timer_max = 16'hFFFFFFFF;	// don't used
				sense_fb = 1'b0;			// discharge
				sense_rdy = 1'b1;
			end

			S_SETUP: begin
				timer_max = 16'd1632;		// 34 us
				sense_fb = 1'b0;			// discharge
				sense_rdy = 1'b0;
			end

			S_CHARGE: begin
				timer_max = 16'd16969;		// 353 us
				sense_fb = 1'b1;			// charge
				sense_rdy = 1'b0;
			end

			S_DISCHARGE: begin
				timer_max = 16'd56353;		// 1174 us
				sense_fb = 1'b0;			// discharge
				sense_rdy = 1'b0;
			end

			default: begin
				timer_max = 16'hxxxxxxxx;
				sense_fb = 1'bx;
				sense_rdy = 1'bx;
			end
		endcase
	end



	//----------------------
	// Measurement & Result
	//----------------------
	always @(posedge clk) begin: MEASURE_CNT
		if (timer_trig)
			sense_cnt <= 15'd0;
		else
			sense_cnt <= sense_cnt + sense_lvds;
	end

	always @(posedge clk) begin: RESULT_OUT
		if ((current_state == S_CHARGE) & timer_trig)
			sense_res <= sense_cnt;
	end

endmodule

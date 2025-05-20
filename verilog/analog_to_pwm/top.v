`default_nettype none

// 0  - GND
// 1  - A0
// 2  - A1
// 3  - A2
// 4  - A3
// 5  - A4
// 6  - A5
// 7  - AREF
// 8  - 3v3
// 9  - GND
// 10 - GND
// 11 - GND
// 12 - 1v35
// 13 - 2v5
// 14 - 1v1
// 15 - VBAT/2
`define MUX_IN 4'd3		// use A2

module top (
	input			clk48,
	input 			usr_btn,
	input 			adc_sense_hi,

	output 			adc_ctrl0,
	output			adc_ctrl1,
	output	[3:0]	adc_mux,

	output			rgb_led0_r,
	output			rgb_led0_g,
	output			rgb_led0_b,
	output			gpio_0
);

	reg [14:0]	adc_res;
	reg 		adc_rdy;
	wire		pwm_out;

	sense sense(.clk(clk48),
				.rst(~usr_btn),
				.sense_lvds(adc_sense_hi),
				.sense_go(1'b1),
				.sense_fb(adc_ctrl0),
				.sense_res(adc_res),
				.sense_rdy(adc_rdy),
	);

	pwm pwm(.rst(~usr_btn),
			.clk(clk48),
			.duty(adc_res),
			.pwm(pwm_out)
	);

	assign gpio_0 = adc_sense_hi;

	// connect PWM to the blue LED
	assign {rgb_led0_r, rgb_led0_g, rgb_led0_b} = {2'b11, ~pwm_out};

	assign adc_mux	 = `MUX_IN;		// configure mux input
	assign adc_ctrl1 = 1'b0;		// enable mux
endmodule

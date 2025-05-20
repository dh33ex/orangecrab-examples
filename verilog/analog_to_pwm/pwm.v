module pwm(
	input				rst,
	input				clk,
	input		[13:0]	duty,
	output reg			pwm
);
	reg [13:0] counter;

    always @(posedge clk) begin
		if (rst) begin
			pwm   <= 1'b0;
			counter <= 14'd0;
		end else begin
			counter <= counter + 1;
			if (counter >= duty) begin
				pwm <= 1'b0;
			end else begin
				pwm <= 1'b1;
			end
		end
	end

endmodule

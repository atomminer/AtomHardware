module m2_abc_reg (
		input clk_h, 
		input clk_h_en,
		input m2_abc_load,
		input	[31:0]		m2_abc_data_in,
		input [31:0]		m2_e_data_in,

output reg [31:0]	a = 32'b0,
output reg [31:0]	b = 32'b0,
output reg [31:0]	c = 32'b0,
output reg [31:0]	d = 32'b0,
output reg [31:0]	e = 32'b0,
output reg [31:0]	f = 32'b0,
output reg [31:0]	g = 32'b0,
output reg [31:0]	h = 32'b0

);
//
always @ (posedge clk_h)
		//if (clk_h_en)
			begin
					if (m2_abc_load)
						begin
										//bitcoin	//protocol 
								a <= 32'h6a09e667;//85e655d6 
								b <= 32'hbb67ae85;//417a1795 
								c <= 32'h3c6ef372;//3363376a 
								d <= 32'ha54ff53a;//624cde5c 
								e <= 32'h510e527f;//76e09589 
								f <= 32'h9b05688c;//cac5f811 
								g <= 32'h1f83d9ab;//cc4b32c1 
								h <= 32'h5be0cd19;//f20e533a 
						end
					else if (clk_h_en)
						begin
								a <= m2_abc_data_in;
								b <= a;
								c <= b;
								d <= c;
								e <= m2_e_data_in;
								f <= e;
								g <= f;
								h <= g;
						end
			end
endmodule	

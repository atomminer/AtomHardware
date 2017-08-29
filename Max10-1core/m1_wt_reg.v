module m1_wt_reg//                          
(
	input clk_h, 
	input m1_wt_reg_en,
	input [31:0] 	w_in,
//	
	output reg 	[31:0] 	w14_t_2 = 32'b0,
	output reg 	[31:0] 	w9_t_7 = 32'b0,	
	output reg	[31:0] 	w1_t_15 = 32'b0,						
	output reg	[31:0] 	w0_t_16 = 32'b0
);
//

reg [31:0]		w15 = 32'b0;
reg [31:0]		w13 = 32'b0;
reg [31:0]		w12 = 32'b0;
reg [31:0]		w11 = 32'b0;
reg [31:0]		w10 = 32'b0;
reg [31:0]		w8 = 32'b0;
reg [31:0]		w7 = 32'b0;
reg [31:0]		w6 = 32'b0;
reg [31:0]		w5 = 32'b0;
reg [31:0]		w4 = 32'b0;
reg [31:0]		w3 = 32'b0;
reg [31:0]		w2 = 32'b0;


always @ (posedge clk_h)
				if (m1_wt_reg_en)
					begin
						w15 <= w_in;
						w14_t_2 <= w15;
						w13 <= w14_t_2;
						w12 <= w13;
						w11 <= w12;
						w10 <= w11;
					end

//
always @ (posedge clk_h)
				if (m1_wt_reg_en)
				begin
						w9_t_7 <= w10;
						w8 <= w9_t_7;
						w7 <= w8;
						w6 <= w7;
						w5 <= w6;
						w4 <= w5;
						w3 <= w4;
						w2 <= w3;
						w1_t_15 <= w2;
						w0_t_16 <= w1_t_15;
				end

endmodule

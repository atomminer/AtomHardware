module m1_abc_reg (
		input clk_h, 
		input clk_h_en,
		input	[31:0]		m1_abc_data_in,
		input [31:0]		m1_e_data_in,
		input		wire			m1_abc_en,

output wire [31:0]	a,
output wire [31:0]	b,
output wire [31:0]	c,
output wire [31:0]	d,
output wire [31:0]	e,
output wire [31:0]	f,
output wire [31:0]	g,
output wire [31:0]	h

);
//

ram_abc_ip	ram_abc_ip_ab (
	.address_a ( 4'b0000 ),//
	.address_b ( 4'b0001 ),//
	.clock ( clk_h ),
	.data_a ( m1_abc_data_in ),
	.data_b ( a ),//
	.enable ( 1'b1 ),////clk_h_en
	.wren_a ( m1_abc_en ),
	.wren_b ( m1_abc_en ),//
	.q_a ( a ),
	.q_b ( b )
	);
//
ram_abc_ip	ram_abc_ip_cd (
	.address_a ( 4'b0000 ),//
	.address_b ( 4'b0001 ),//
	.clock ( clk_h ),
	.data_a ( b ),
	.data_b ( c),//
	.enable ( 1'b1 ),//clk_h_en
	.wren_a ( m1_abc_en ),
	.wren_b ( m1_abc_en ),//
	.q_a ( c ),
	.q_b ( d )
	);
//
ram_abc_ip	ram_abc_ip_ef (
	.address_a ( 4'b0000 ),//
	.address_b ( 4'b0001 ),//
	.clock ( clk_h ),
	.data_a ( m1_e_data_in ),
	.data_b ( e ),//
	.enable ( 1'b1 ),// clk_h_en
	.wren_a ( m1_abc_en ),
	.wren_b ( m1_abc_en ),//
	.q_a ( e ),
	.q_b ( f )
	);
//
ram_abc_ip	ram_abc_ip_gh (
	.address_a ( 4'b0000 ),//
	.address_b ( 4'b0001 ),//
	.clock ( clk_h ),
	.data_a ( f ),
	.data_b ( g ),// 
	.enable ( 1'b1 ),//clk_h_en
	.wren_a ( m1_abc_en ),
	.wren_b ( m1_abc_en ),//
	.q_a ( g ),
	.q_b ( h )
	);
//
	
endmodule

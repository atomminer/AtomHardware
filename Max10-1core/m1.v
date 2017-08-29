//m1_sha256_data
//	Имя	бит	Dword	
//addr			name							dwords
//0			H0									1	
//1			H1									1	
//2			H2									1	
//3			H3									1	
//4			H4									1	
//5			H5									1	
//6			H6									1	
//7			H7									1
	
//8			Merkel root [255:224]		1	
//9			timestamp						1	
//10			bits								1	
//11			nonce								1	
//
//*********Constant block***********
//addr			   name							dwords
//0  12			32'h80000000					1	
//1  13			32'h0								1	
//2  14			32'h0								1	
//3  15			32'h0								1	
//4  16			32'h0								1	
//5  17			32'h0								1	
//6  18			32'h0								1	
//7  19			32'h0								1	
//8  20			32'h0								1	
//9  21			32'h0								1	
//10 22			32'h0								1	
//11 23			32'h00000280					1	
//
//addr 0 - 7  - inits for M0 or previous hashs for M1
//addr 8 - 23 - M0 or M1


module m1 (
		input 		clk_h, 
		input [31:0]	m1_next_nonce,
		input 		m1_wr_nonce,		
//m1_header_ram_ip
		input [4:0] 	m1_header_ram_addr_a,
		input [4:0] 	m1_header_ram_addr_b,
		input [31:0]	data_from_host,
		input				m1_header_ram_wren_a,
//m1_abc_reg_ip		
		input					m1_abc_en,
		input 				m1_abc_load,
//m1_wt_reg
		input 				m1_wt_reg_en,		
		input 				m1_wt_sw,
				
//k_rom_address
		input [5:0] 	m1_k_rom_address,
		input 			m1_k_rom_clkh_en,	
//
output wire [31:0]	m1_h_0_3,
output wire [31:0]	m1_h_4_7		
			);		
//			
//	m1_header_ram_ip	
wire [31:0]			m1_header_ram_outa;
wire [31:0]			m1_header_ram_outb;
//
//abc_reg
wire [31:0]			m1_abc_data_in;
wire [31:0]			m1_e_data_in;
wire [31:0]			a;
wire [31:0]			b;
wire [31:0]			c;
wire [31:0]			d;
wire [31:0]			e;
wire [31:0]			f;
wire [31:0]			g;
wire [31:0]			h;
//
//m1_wt_reg
wire [31:0]			wt_in_wire;
wire [31:0]			wt_in;
wire [31:0]			sigma0;
wire [31:0]			sigma1;
wire 	[31:0] 	w14_t_2;
wire 	[31:0] 	w9_t_7;
wire	[31:0] 	w1_t_15;					
wire	[31:0] 	w0_t_16;

//k_rom
wire [31:0] k;
//m1_comby
wire [31:0] t1t2;
wire [31:0] dt1;


			
//
m1_header_ram_ip	m1_header_ram_ip (
	.address_a ( m1_header_ram_addr_a ),
	.address_b ( m1_header_ram_addr_b ),
	.clock ( clk_h ),	
	.data_a ( data_from_host ),
	.data_b ( m1_next_nonce ),	
	.enable ( 1'b1 ),	
	.wren_a ( m1_header_ram_wren_a ),
	.wren_b ( m1_wr_nonce ),
	.q_a ( m1_header_ram_outa ),
	.q_b ( m1_header_ram_outb )	
	);
//
assign m1_h_0_3 = m1_header_ram_outa + a;
assign m1_h_4_7 = m1_header_ram_outb + e;
//
m1_abc_reg m1_abc_reg  (
		.clk_h(clk_h), 
		.clk_h_en(m1_abc_en),
		.m1_abc_data_in(m1_abc_data_in),
		.m1_e_data_in(m1_e_data_in),
		.m1_abc_en(m1_abc_en),

		.a(a),
		.b(b),
		.c(c),
		.d(d),
		.e(e),
		.f(f),
		.g(g),
		.h(h)

);
//
assign m1_abc_data_in = m1_abc_load ? m1_header_ram_outa : t1t2;
assign m1_e_data_in  = m1_abc_load ?  m1_header_ram_outb : dt1;

//
m1_wt_reg 	m1_wt_reg (
	.clk_h(clk_h), 
	.m1_wt_reg_en(m1_wt_reg_en),
	.w_in(wt_in),
//	
	.w14_t_2(w14_t_2),
	.w9_t_7(w9_t_7),	
	.w1_t_15(w1_t_15),						
	.w0_t_16(w0_t_16)
							);
//
assign sigma0 = {w1_t_15[6:0],w1_t_15[31:7]} ^ {w1_t_15[17:0],w1_t_15[31:18]} ^ {3'b000,w1_t_15[31:3]};
assign sigma1 = {w14_t_2[16:0],w14_t_2[31:17]} ^ {w14_t_2[18:0],w14_t_2[31:19]} ^ {10'b00_0000_0000,w14_t_2[31:10]};
assign wt_in_wire = sigma1 + w9_t_7 + sigma0 +  w0_t_16;
assign wt_in = m1_wt_sw ? wt_in_wire : m1_header_ram_outa;														
//
k_rom_ip	k_rom_ip (
	.address ( m1_k_rom_address ),
	.clken ( m1_k_rom_clkh_en ),
	.clock ( clk_h ),
	.q ( k )
	);
						
//
m1_comby m1_comby(
					.a(a),
					.b(b),
					.c(c),
					.d(d),
					.e(e),
					.f(f),
					.g(g),
					.h(h),

					.k(k),
					.wt_in(wt_in),
					//
					.t1t2(t1t2),
					.dt1(dt1)
							);	
//

endmodule							
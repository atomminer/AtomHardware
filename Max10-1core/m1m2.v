 module m1m2 (		
		input clk_h, 		 
/////////////////////////////////// m1
		input [31:0]	m1_next_nonce,
		input 			m1_wr_nonce,		
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
				
//m1_k_rom
		input [5:0] 	m1_k_rom_address,
		input 			m1_k_rom_clkh_en,	
//
////////////////////////////////////m2
		input				m2_target_en_t0,
//m2_header_ram_ip
		input [3:0] 	m2_header_ram_addr_a,
		input [3:0] 	m2_header_ram_addr_b,
		input				m2_header_ram_wren,
//
//m2_abc_reg
		input				m2_abc_en,
		input 			m2_abc_load,
//		input				m2_rom_init_clk_en,
//		input	[2:0]		m2_rom_initabc_addr_a,
//		input	[2:0]		m2_rom_initabc_addr_b,
//
//m2_wt_reg
		input				m2_wt_reg_en,
		input				m2_wt_sw,
//
//k_rom_address
		input [5:0] 	m2_k_rom_address,
		input 			m2_k_rom_clkh_en,
// 
//target_polling
		input 			catch_bits,
		input 			host_break,

		output wire m2_ticket2moon
					);
					
					
	//
//
//m1
wire [31:0]	m1_h_0_3;
wire [31:0]	m1_h_4_7;

//
//m2
wire [31:0]	m2_h_0_3;
wire [31:0]	m2_h_4_7;




//
m1 m1 (
		.clk_h(clk_h), 
		.m1_next_nonce(m1_next_nonce),
		.m1_wr_nonce(m1_wr_nonce),		
//m1_header_ram_ip
		.m1_header_ram_addr_a(m1_header_ram_addr_a),
		.m1_header_ram_addr_b(m1_header_ram_addr_b),
		.data_from_host(data_from_host),
		.m1_header_ram_wren_a(m1_header_ram_wren_a),
//m1_abc_reg_ip		
		.m1_abc_en(m1_abc_en),
		.m1_abc_load(m1_abc_load),
//m1_wt_reg
		.m1_wt_reg_en(m1_wt_reg_en),		
		.m1_wt_sw(m1_wt_sw),
				
//k_rom_address
		.m1_k_rom_address(m1_k_rom_address),
		.m1_k_rom_clkh_en(m1_k_rom_clkh_en),	
//
		.m1_h_0_3(m1_h_0_3),
		.m1_h_4_7(m1_h_4_7)	
							);
//
m2 m2 (
					.clk_h(clk_h),  
			//
					.data_from_host(data_from_host),
					.target_en(m2_target_en_t0),
			//m2_header_ram_ip
					.m2_header_ram_addr_a(m2_header_ram_addr_a),
					.m2_header_ram_addr_b(m2_header_ram_addr_b),
					.m1_h_0_3(m1_h_0_3),
					.m1_h_4_7(m1_h_4_7),	
					.m2_header_ram_wren(m2_header_ram_wren),
			//
			//m2_abc_reg
					.m2_abc_en(m2_abc_en),
					.m2_abc_load(m2_abc_load),
					//.m2_rom_init_clk_en(m2_rom_init_clk_en),
					//.m2_rom_initabc_addr_a(m2_rom_initabc_addr_a),
					//.m2_rom_initabc_addr_b(m2_rom_initabc_addr_b),
			//
			//m2_wt_reg
					.m2_wt_reg_en(m2_wt_reg_en),
					.m2_wt_sw(m2_wt_sw),
			//
			//k_rom_address
					.m2_k_rom_address(m2_k_rom_address),
					.m2_k_rom_clkh_en(m2_k_rom_clkh_en),
					
			//
			.catch_bits(catch_bits),
			.host_break(host_break),
			//
			
			.m2_ticket2moon(m2_ticket2moon)
							);
//



endmodule









							
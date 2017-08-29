//takes previous hashes h0...h7 that are the data[511:256] or d0,d1,d2...d7. loads them into ramheader at addrs 0 ... 7.
//Constant content, <80000000, 0, 0, 0, 0, 0, 0, 100> is used at addrs 8 ... 15 in ramheader. 
//init abc reg by consts according protocol
//	a = 6a09e667
//	b = bb67ae85
//	c = 3c6ef372
//	d = a54ff53a
//	e = 510e527f
//	f = 9b05688c
//	g = 1f83d9ab
//	h = 5be0cd19.
//
module m2 (

		input 	clk_h,  
//
		input	[31:0]	data_from_host,
		input 			target_en,
//m2_header_ram_ip
		input [3:0] 	m2_header_ram_addr_a,
		input [3:0] 	m2_header_ram_addr_b,
		input [31:0]	m1_h_0_3,
		input [31:0]	m1_h_4_7,	
		input				m2_header_ram_wren,
//
//m2_abc_reg
		input				m2_abc_en,
		input 			m2_abc_load,
//
//m2_wt_reg
		input				m2_wt_reg_en,
		input				m2_wt_sw,
//
//k_rom_address
		input [5:0] 	m2_k_rom_address,
		input 			m2_k_rom_clkh_en,
//
		input 			catch_bits,
		input 			host_break,		
//
//output wire [31:0]	m2_h_0_3,
//output wire [31:0]	m2_h_4_7	

output reg 			m2_ticket2moon = 1'b0
			
			);
			
//
//	m2_header_ram_ip	
wire [31:0]			m2_header_ram_outa;
wire [31:0]			m2_header_ram_outb;
//
//abc_reg
wire [31:0]			m2_abc_data_in;
wire [31:0]			m2_e_data_in;
wire [31:0]			a;
wire [31:0]			b;
wire [31:0]			c;
wire [31:0]			d;
wire [31:0]			e;
wire [31:0]			f;
wire [31:0]			g;
wire [31:0]			h;
//
//	m2_rom_initabc		
wire [31:0] 	m2_init_a;
wire [31:0] 	m2_init_b;
//
//m2_wt_reg
wire [31:0]			wt_in_wire;
wire [31:0]			wt_in;
wire [31:0]			sigma0;
wire [31:0]			sigma1;
wire 	[31:0] 	w14_t_2;
wire 	[31:0] 	w9_t_7;
wire	[31:0] 	w1_t_15;					
wire	[31:0] 	w0_t_16;
//
//k_rom
wire [31:0] k;
//m1_comby
wire [31:0] t1t2;
wire [31:0] dt1;			
//
reg [31:0]	hash0 = 32'hffffffff, hash1 = 32'hffffffff,hash2 = 32'hffffffff,hash3 = 32'hffffffff,hash4 = 32'hffffffff,hash5 = 32'hffffffff,hash6 = 32'hffffffff,hash7 = 32'hffffffff;
reg 			catch_bits_r = 1'b0;
//
reg [255:0] target = 256'h0;
//
always @ (posedge clk_h)
	begin
		if (target_en)
			begin	
				target[31:0] <= data_from_host;
				target[63:32] <= target[31:0];
				target[95:64] <= target[63:32];
				target[127:96] <= target[95:64];
				target[159:128] <= target[127:96];
				target[191:160] <= target[159:128];
				target[223:192] <= target[191:160];
				target[255:224] <= target[223:192];
				
			end
	end

//
m2_header_ram_ip 	m2_header_ram_ip (
							.address_a ( m2_header_ram_addr_a ),
							.address_b ( m2_header_ram_addr_b ),
							.clock ( clk_h ),
							.data_a ( m1_h_0_3 ),
							.data_b ( m1_h_4_7 ),
							.enable ( 1'b1 ),
							.wren_a ( m2_header_ram_wren ),
							.wren_b ( m2_header_ram_wren ),
							.q_a ( m2_header_ram_outa ),
							.q_b ( m2_header_ram_outb )
							);
//
//assign m2_h_0_3 = m2_header_ram_outa + a;
//assign m2_h_4_7 = m2_header_ram_outb + e;
//
//
m2_abc_reg m2_abc_reg  (
		.clk_h(clk_h), 
		.clk_h_en(m2_abc_en),
		.m2_abc_load(m2_abc_load),
		.m2_abc_data_in(m2_abc_data_in),
		.m2_e_data_in(m2_e_data_in),
//
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
//
assign m2_abc_data_in =  t1t2;//   m1_h_0_3 m2_abc_load ? m2_init_a :
assign m2_e_data_in  =  dt1;//    m1_h_4_7  m2_abc_load ? m2_init_b : 
//
//m2_wt_reg
m1_wt_reg 	m2_wt_reg (
	.clk_h(clk_h), 
	.m1_wt_reg_en(m2_wt_reg_en),
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
assign wt_in = m2_wt_sw ? wt_in_wire : m2_header_ram_outa;	//												
//
//
k_rom_ip	m2_k_rom_ip (
	.address ( m2_k_rom_address ),
	.clken ( m2_k_rom_clkh_en ),
	.clock ( clk_h ),
	.q ( k )
	);						
//
m1_comby m2_comby(
					.a(a),
					.b(b),
					.c(c),
					.d(d),
					.e(e),
					.f(f),
					.g(g),
					.h(h),
//
					.k(k),
					.wt_in(wt_in),
					//
					.t1t2(t1t2),
					.dt1(dt1)
							);	
//
// catch bits
		always @ (posedge clk_h)
				catch_bits_r <= catch_bits;
//
		always @ (posedge clk_h)
			if (catch_bits)
				begin
									//  bit    		//protocol
					hash0 <= a + 32'h6a09e667;//85e655d6 
					hash1 <= b + 32'hbb67ae85;//417a1795 
					hash2 <= c + 32'h3c6ef372;//3363376a 
					hash3 <= d + 32'ha54ff53a;//624cde5c 
					hash4 <= e + 32'h510e527f;//76e09589 
					hash5 <= f + 32'h9b05688c;//cac5f811 
					hash6 <= g + 32'h1f83d9ab;//cc4b32c1 
					hash7 <= h + 32'h5be0cd19;//f20e533a 
				end
//
		always @ (posedge clk_h)
			//if (host_break)
				//m2_ticket2moon <= 1'b0;
			 if (catch_bits_r)
				m2_ticket2moon <= {hash7,hash6,hash5,hash4,hash3,hash2,hash1,hash0} <= target;/// must be <=
			else	
				m2_ticket2moon <= 1'b0;


endmodule							

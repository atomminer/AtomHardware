module m2_sm (

		input clk_h, 
		input host_break,
		input start_stop,
		input go_m2,
//
output reg		m2_header_ram_wren_a = 1'b0,

output reg		m2_abc_load = 1'b0,
output reg		m2_abc_en = 1'b1,
output reg		m2_wt_reg_en = 1'b0,
output reg		m2_wt_sw = 1'b0,

output reg	[3:0] 	m2_header_ram_addr_a = 4'b0,
output reg	[3:0] 	m2_header_ram_addr_b = 4'b0,
output reg	[5:0] 	m2_k_rom_address = 6'b0,
output reg				m2_k_rom_clkh_en = 1'b0,
output reg				catch_bits = 1'b0

);
//
 localparam		M2_IDLE			 				= 4'b0000,
					M2_LOAD_HEADER_WRHDR			= 4'b0001,
					M2_INIT_M2		   			= 4'b0010,
					M2_INIT_K		   			= 4'b0011,
					M2_INIT_K1						= 4'b0100,
					M2_INIT_ABC						= 4'b0101, 
					M2_FIRST16			   		= 4'b0110,
					M2_READ_HEADER_HASHS			= 4'b0111,
					M2_CALC_HASHS 					= 4'b1000;
					
//
//timers
reg		 	load_one_shoot_start = 1'b0;
reg [24:0]	load_num 		= 25'b0;
reg			load_num_en 	= 1'b0;
reg			read_header = 1'b0;

reg			time2k = 1'b0;
reg			time2wt_sw = 1'b0;

reg 			round_abc_wt_one_shoot = 1'b0;
reg [4:0]	round_abc_wt = 5'b0;
reg			round_abc_wt_en = 1'b0;
reg			round_abc_wt_res = 1'b0;

//
reg [3:0]	hash_state = 4'b0;
reg [3:0]	hash_next_state = 4'b0;

//
reg				k_res = 1'b0;

//
always @ (posedge clk_h)
begin
	if (host_break | ~start_stop)
	hash_state <= M2_IDLE;//
	else
	hash_state <= hash_next_state;
end
//

always @ (*)
begin
	load_one_shoot_start <= 1'b0;
	load_num_en <= 1'b0;
	m2_header_ram_wren_a <= 1'b0;


	round_abc_wt_one_shoot <= 1'b0;
	round_abc_wt_en <= 1'b0;
	read_header <= 1'b0;
	m2_k_rom_clkh_en <= 1'b0;
	m2_abc_load <= 1'b0;
	m2_abc_en <= 1'b0;
	m2_wt_reg_en <= 1'b0;
	k_res <= 1'b0;
	m2_wt_sw <= 1'b0;
	catch_bits <= 1'b0;
	
	case (hash_state)
			M2_IDLE: begin//0000
									if (go_m2) 
										begin
											hash_next_state <= M2_LOAD_HEADER_WRHDR; 
										end
									else 				
										begin
											hash_next_state <= M2_IDLE; 				
										end
						end
								//						
			M2_LOAD_HEADER_WRHDR: begin // 0001
												begin
													round_abc_wt_one_shoot <= 1'b1;
													round_abc_wt_en <= 1'b1;
													hash_next_state <= M2_INIT_M2;
												round_abc_wt_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_sw <= 1'b1;
												end		
								end
								//	
			M2_INIT_M2: begin //0010
											round_abc_wt_en <= 1'b1;
											m2_header_ram_wren_a <= 1'b1;
											k_res <= 1'b1;
												round_abc_wt_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_sw <= 1'b1;
											catch_bits <= 1'b1;
											hash_next_state <= M2_INIT_K;
								end
								//	
			M2_INIT_K: begin // 0011
											m2_header_ram_wren_a <= 1'b1;
											round_abc_wt_en <= 1'b1;
											if (time2k)
											begin
											m2_k_rom_clkh_en <= 1'b1;
											read_header <= 1'b1;
											m2_header_ram_wren_a <= 1'b1;
											hash_next_state <= M2_INIT_K1;//
											end
											else 
											hash_next_state <= M2_INIT_K;		
							end
								//
			M2_INIT_K1: begin //	0100
											round_abc_wt_en <= 1'b1;
											m2_abc_load <= 1'b1;
											m2_abc_en <= 1'b1;
											m2_k_rom_clkh_en <= 1'b1;
											read_header <= 1'b1;
											m2_wt_reg_en <= 1'b1;
											hash_next_state <= M2_INIT_ABC;
							end
						//						
			M2_INIT_ABC: begin //0101
												round_abc_wt_en <= 1'b1;
												read_header <= 1'b1;
												m2_abc_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_reg_en <= 1'b1;
												hash_next_state <= M2_FIRST16;
								end
								//
			M2_FIRST16: begin // 0110
												round_abc_wt_en <= 1'b1;
												read_header <= 1'b1;
												m2_abc_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_reg_en <= 1'b1;
												if (time2wt_sw)
													begin 
															m2_wt_sw <= 1'b1;
															hash_next_state <= M2_CALC_HASHS;//
													end
												else
												hash_next_state <= M2_FIRST16;	
							end
								//
			M2_CALC_HASHS: begin // 1000
												m2_abc_en <= 1'b1;
																				//round_abc_wt_en <= 1'b1;
												m2_wt_reg_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_sw <= 1'b1;	
												if (go_m2)//
												begin
												m2_abc_en <= 1'b0;
												m2_wt_reg_en <= 1'b1;
												m2_k_rom_clkh_en <= 1'b1;
												m2_wt_sw <= 1'b1;	
												hash_next_state <= M2_LOAD_HEADER_WRHDR;//
												end
											else
												hash_next_state <= M2_CALC_HASHS;
								end
								//
									default: 	begin 	hash_next_state <= M2_IDLE; end
	endcase
end
//
// header addresses
	always @ (posedge clk_h)
		begin		
				if (host_break)
					begin
							m2_header_ram_addr_a <= 4'b0011;
							m2_header_ram_addr_b <= 4'b0111;
					end
				else if (round_abc_wt_one_shoot)// 
					begin
							m2_header_ram_addr_a <= 4'b0011;
							m2_header_ram_addr_b <= 4'b0111;
					end
	
							else if (read_header)
					begin
						m2_header_ram_addr_a <= m2_header_ram_addr_a + 1'b1;
						m2_header_ram_addr_b <= m2_header_ram_addr_b + 1'b1;
					end	
					
				else if (m2_header_ram_wren_a )//
					begin
							m2_header_ram_addr_a <= m2_header_ram_addr_a - 1'b1;
							m2_header_ram_addr_b <= m2_header_ram_addr_b - 1'b1;
					end					
		end
//		
//
// r_ROM addresses
	always @ (posedge clk_h)
				if (k_res)
					m2_k_rom_address <= 6'b0;
				else if (m2_k_rom_clkh_en)
					m2_k_rom_address <= m2_k_rom_address + 6'b000001;	
//
//
// timers state machine
	always @ (posedge clk_h)
	begin
		if (load_num_en)
		begin
			load_num[24:1] <= load_num[23:0];
			load_num[0] <= load_one_shoot_start;
		end
	end

//	
	always @ (posedge clk_h)
	begin
		if (host_break | round_abc_wt_res)
				round_abc_wt <= 5'b0;
		else if (round_abc_wt_en )
				round_abc_wt <= round_abc_wt + 5'b1;
	end	
//
	always @ (posedge clk_h)
	begin
			time2k <= round_abc_wt == 5'h3;//3	
			time2wt_sw <= round_abc_wt == 5'h15;//21
			round_abc_wt_res <= round_abc_wt == 5'h17;//23
	end	
	
	endmodule
	
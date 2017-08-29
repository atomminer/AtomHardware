module m1_sm (

		input clk_h, 
		input host_break,
		input lock,
		input	block_data_en,
		input header_rdy,
		input start_stop,
//
output reg		m1_header_ram_wren_a = 1'b0,
output reg		load_bits = 1'b0,
output reg		m1_abc_load_r = 1'b0,
output reg		m1_abc_en_r = 1'b1,
output reg		m1_wt_reg_en = 1'b0,
output reg		m1_wt_sw = 1'b0,
output reg		m1_wr_nonce = 1'b0,
output reg	[4:0] 	m1_header_ram_addr_a = 5'b0,
output reg	[4:0] 	m1_header_ram_addr_b = 5'b0,
output reg	[5:0] 	m1_k_rom_address = 6'b0,
output reg				m1_k_rom_clkh_en = 1'b1,
output reg 			go_m2 = 1'b0
);
//
 localparam		M1_IDLE			 				= 4'b0000,
					M1_LOAD_HEADER_RDHOST		= 4'b0001,
					M1_LOAD_HEADER_BITS			= 4'b0010,
					M1_LOAD_HEADER_NONCE			= 4'b0011,
					M1_LOAD_HEADER_WRHDR			= 4'b0100,
					M1_INIT_M1		   			= 4'b0101,
					M1_INIT_K		   			= 4'b0110,
					M1_INIT_ABC						= 4'b0111,				
//					
					M1_FIRST16			   = 4'b1000,
					M1_READ_HEADER_HASHS	= 4'b1001,
					M1_CALC_HASHS			= 4'b1010,
					M1_FINISH            = 4'b1011,
					M1_WAIT_INIT_M1		= 4'b1100;
					//M1_RECOVERY          = 4'b1111;
//
//timers
//reg		 	load_one_shoot_start = 1'b0;
reg [4:0]	load_num 		= 5'b0;
reg			load_num_en 	= 1'b0;

reg			time2k = 1'b0;
reg			time2abc = 1'b0;
reg			time2wt_sw = 1'b0;
reg			time2finish = 1'b0;
reg 			m1_time2rd_hashs = 1'b0;

reg 			round_abc_wt_one_shoot = 1'b0;
reg [6:0]	round_abc_wt = 7'b0;
reg			round_abc_wt_en = 1'b0;
reg			round_abc_wt_res = 1'b0;

//
//
(* keep *) reg [3:0]	hash_state = 4'b0;
(* keep *) reg [3:0]	hash_next_state = 4'b0;

reg 			header_loded = 1'b0;
reg			read_header = 1'b0;
//reg			time2bits = 1'b0;
//
reg				k_res = 1'b0;
reg				go_m2_r = 1'b0;

reg		m1_abc_load = 1'b0;
reg		m1_abc_en = 1'b1;

reg		time2loadnonce = 1'b0;


//
always @ (posedge clk_h)
begin
	if (host_break )// 
	hash_state <= M1_IDLE;//
	else
	hash_state <= hash_next_state;
end
//
always @ (posedge clk_h)
begin
	m1_abc_load_r <= m1_abc_load;
	m1_abc_en_r <= m1_abc_en;
	go_m2 <= go_m2_r;
end

//
always @ (*)
begin
	load_num_en <= 1'b0;
	m1_header_ram_wren_a <= 1'b0;
	load_bits <= 1'b0;
	round_abc_wt_one_shoot <= 1'b0;
	round_abc_wt_en <= 1'b0;
	read_header <= 1'b0;
	m1_wr_nonce <= 1'b0;
	
	m1_abc_load <= 1'b0;
	m1_abc_en <= 1'b0;
	m1_wt_reg_en <= 1'b0;
	read_header <= 1'b0;		
	m1_k_rom_clkh_en <= 1'b0; 
	k_res <= 1'b0;
	m1_wt_sw <= 1'b0;
	go_m2_r <= 1'b0;
	time2loadnonce <= 1'b0;
	round_abc_wt_res <= 1'b0;
	
	case (hash_state)
			M1_IDLE: begin//0000
									if (block_data_en)// 
										begin
											hash_next_state <= M1_LOAD_HEADER_RDHOST; 
										end
									else 				
										begin
											hash_next_state <= M1_IDLE; 				
										end
						end
								//
			M1_LOAD_HEADER_RDHOST: begin 	//0001
											m1_header_ram_wren_a <= 1'b1;
											load_num_en <= 1'b1;
											hash_next_state <= M1_LOAD_HEADER_BITS;//
								end
								//
			M1_LOAD_HEADER_BITS: begin //0010
											if (block_data_en)
												begin
													load_num_en <= 1'b1;
													m1_header_ram_wren_a <= 1'b1;
													hash_next_state <= M1_LOAD_HEADER_BITS;
												end
											else if (start_stop) //time2bits
														begin
															hash_next_state <= M1_INIT_M1;// 
														end
											else if (host_break)
															hash_next_state <= M1_IDLE;
											else 
															hash_next_state <= M1_LOAD_HEADER_BITS;
													
								end
								//
			M1_LOAD_HEADER_NONCE: begin //0011
											load_num_en <= 1'b1;
											m1_header_ram_wren_a <= 1'b0;//1
											hash_next_state <= M1_LOAD_HEADER_WRHDR;	
								end					
								//								
			M1_LOAD_HEADER_WRHDR: begin // 0100
											load_num_en <= 1'b1;
											m1_header_ram_wren_a <= 1'b1;
											if (header_loded)
												begin	
													round_abc_wt_one_shoot <= 1'b1;
													round_abc_wt_en <= 1'b1;
													hash_next_state <= M1_INIT_M1;
												end
											else 
													hash_next_state <= M1_LOAD_HEADER_WRHDR;
								end
								//	
			M1_INIT_M1: begin //0101
											m1_abc_load <= 1'b1;
											m1_abc_en <= 1'b1;
											round_abc_wt_en <= 1'b1;
											read_header <= 1'b1;
											k_res <= 1'b1;
											hash_next_state <= M1_INIT_K;
								end
								//
			M1_INIT_K: begin // 0110
											round_abc_wt_en <= 1'b1;
											read_header <= 1'b1;
											m1_abc_load <= 1'b1;
											m1_abc_en <= 1'b1;
											if (time2k)
											begin 
											m1_k_rom_clkh_en <= 1'b1;
											m1_wt_reg_en <= 1'b1;
											hash_next_state <= M1_INIT_ABC;
											end
											else 
											hash_next_state <= M1_INIT_K;		
							end
								//				
			M1_INIT_ABC: begin //0111
											round_abc_wt_en <= 1'b1;
											read_header <= 1'b1;
											m1_abc_load <= 1'b1;
											m1_abc_en <= 1'b1;
											m1_k_rom_clkh_en <= 1'b1;
											m1_wt_reg_en <= 1'b1;
									if (time2abc)	begin
											m1_abc_load <= 1'b0;
											time2loadnonce <= 1'b1;
											hash_next_state <= M1_FIRST16;
														end
									else 				begin
											hash_next_state <= M1_INIT_ABC; 
														end
							end
							//
			M1_FIRST16: begin //1000
											round_abc_wt_en <= 1'b1;
											read_header <= 1'b1;
											m1_abc_en <= 1'b1;
											m1_k_rom_clkh_en <= 1'b1;
											m1_wt_reg_en <= 1'b1;
											time2loadnonce <= 1'b1;
											if (time2wt_sw)
												begin
													m1_wr_nonce <= 1'b1;
													m1_wt_sw <= 1'b1;
													hash_next_state <= M1_READ_HEADER_HASHS;
												end
											else
											hash_next_state <= M1_FIRST16;
							end
							//
			M1_READ_HEADER_HASHS: begin //1001
											round_abc_wt_en <= 1'b1;
											m1_abc_en <= 1'b1;
											m1_k_rom_clkh_en <= 1'b1;
											m1_wt_reg_en <= 1'b1;
											m1_wt_sw <= 1'b1;
											if (m1_time2rd_hashs)
											begin
											go_m2_r <= 1'b1;	
											hash_next_state <= M1_CALC_HASHS;
											end
											else
											hash_next_state <= M1_READ_HEADER_HASHS;
			
							end
							//
			M1_CALC_HASHS: begin //1010
											round_abc_wt_en <= 1'b1;
											m1_abc_en <= 1'b1;
											m1_k_rom_clkh_en <= 1'b1;
											m1_wt_reg_en <= 1'b1;
											m1_wt_sw <= 1'b1;
											read_header <= 1'b1;
											if (time2finish)
												begin
												round_abc_wt_res <= 1'b1;
												read_header <= 1'b0;
												round_abc_wt_one_shoot <= 1'b1;
												round_abc_wt_en <= 1'b1;
												hash_next_state <= M1_FINISH;//
												end
											else
													hash_next_state <= M1_CALC_HASHS;	
							end
							//
			M1_FINISH	: begin // 1011
										if (start_stop)
											begin
													round_abc_wt_en <= 1'b1;
													m1_abc_en <= 1'b1;
													m1_k_rom_clkh_en <= 1'b1;
													m1_wt_reg_en <= 1'b1;
													m1_wt_sw <= 1'b1;
													hash_next_state <= M1_INIT_M1;//
											end
										else 
												hash_next_state <= M1_IDLE;
								end
								//
			M1_WAIT_INIT_M1: begin//1100
													round_abc_wt_one_shoot <= 1'b1;
													round_abc_wt_en <= 1'b1;
													hash_next_state <= M1_INIT_M1;
							end
							//						
	default: 	begin 	hash_next_state <= M1_IDLE; end
	
	endcase
end
//
// header addresses
	always @ (posedge clk_h)
		begin		
				if (host_break)
							m1_header_ram_addr_a <= 5'b0;
					
				else if (round_abc_wt_one_shoot | m1_time2rd_hashs)
							m1_header_ram_addr_a <= 5'b00100;
				
				else if (read_header)
						m1_header_ram_addr_a <= m1_header_ram_addr_a + 5'b1;
						
				else if (m1_header_ram_wren_a | m1_wr_nonce)// 
							m1_header_ram_addr_a <= m1_header_ram_addr_a + 5'b1;			
		end
//		
	always @ (posedge clk_h)
		begin		
				if (host_break | time2abc | time2loadnonce)
					m1_header_ram_addr_b <= 5'hb;
					
				else if (round_abc_wt_one_shoot | m1_time2rd_hashs)
							m1_header_ram_addr_b <= 5'b0;
							
				else if (read_header)
						m1_header_ram_addr_b <= m1_header_ram_addr_b + 5'b1;
		end						
//
// r_ROM addresses
	always @ (posedge clk_h)
				if (k_res)
					m1_k_rom_address <= 6'b0;
				else if (m1_k_rom_clkh_en)
					m1_k_rom_address <= m1_k_rom_address + 6'b000001;	
//
	always @ (posedge clk_h)
	begin
		if (host_break | ~load_num_en)
			load_num <= 5'b0;
		else if (load_num_en)
			load_num <= load_num + 5'b1;
	end
//	
	always @ (posedge clk_h)
	begin				
		//time2bits <= load_num == 5'ha;//[10]
		header_loded <= load_num == 5'h18;//[24]
	end
//
//
	always @ (posedge clk_h)
	begin
		if (host_break | round_abc_wt_res)
				round_abc_wt <= 7'b0;
		else if (round_abc_wt_en )
				round_abc_wt <= round_abc_wt + 7'b1;
	end	
//
	always @ (posedge clk_h)
	begin
			time2k <= round_abc_wt == 7'h4;//4
			time2abc <= round_abc_wt == 7'h5;//5	
			time2wt_sw <= round_abc_wt == 7'h16;//22
			m1_time2rd_hashs <= round_abc_wt == 7'h40;//64
			time2finish <= round_abc_wt == 7'h45;//68;
	end
		//
	
	
endmodule

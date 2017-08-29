//
// STATUS [31:0]  
//     reserve      	   11 10 9 8 [7:0]
//								 |  | | |    clk_h_frequency
//				             |  | | start_stop-- 1 => start(calculations in progress); 0 => stop (waiting start or new block)
//                       |  | ready4hash  -- 1 => ready for hash							
//                       |  hash_completed-- 1 => hash completed; 0 => not  completed
//                       bussy -- 1 => reconfig  clk_h_frequency in progress	
//                   											
module system_control (
input			clk_h,
input			host_break,
input 		go_reconfig,
input			start_stop,
input [7:0]	hash_frequency,
input 		reconfig_ok,
input 		busy,
input			status_go,
//
input		uart_cou_dword_en,
input		wr_block,
input		set_target,
input		set_timestamp,
input		set_nonce,
input		cou_dword_res,
input		link_rx_wr_cmplt,
//
input [31:0]	data_from_host,
//
input				m2_ticket2moon,
input [31:0] 	current_nonce,
input				hash_cmplt,
input				m1_wr_nonce,
//
output reg [5:0]	system_ram_dword_addr = 6'h0,
output reg [31:0]	system_ram_dword_data = 32'b0,
output reg			system_ram_dword_we = 1'b0,
//
output reg 			target_en = 1'b0,
//output reg 			timestamp_en = 1'b0,
output reg 			block_data_en = 1'b0,
output reg 			wr_start_nonce = 1'b0,
//
output reg 			go_success = 1'b0,
output reg 			go_unsucces = 1'b0
			

	);
//
localparam	SC_IDLE 					= 4'b0000,
				SC_WRBLOCK1				= 4'b0001,
				SC_WRBLOCK2				= 4'b0010,
				SC_SETTARGET1 			= 4'b0011,
				SC_SETTARGET2 			= 4'b0100,
				SC_SETIMESTAMP 		= 4'b0101,
				SC_HASHSUCCES 			= 4'b0110,
				SC_HASHUNSUCCES		= 4'b0111,
				SC_RECONFIG    		= 4'b1000,
				SC_SETSTATUS 			= 4'b1001,
				SC_SETCURRENTNONCE 	= 4'b1010;
				
//
reg [3:0]	sc_sm_state = 4'b0;
reg [3:0]	sc_sm_state_next = 4'b0;
//	
reg system_ram_dword_addr_en_r = 1'b0;
reg system_ram_dword_addr_en = 1'b0;	

reg set_wr_block_adrr_r = 1'b0;
reg set_wr_block_adrr = 1'b0;
reg block_data_en_r = 1'b0;
reg set_target_adrr = 1'b0;
reg set_target_adrr_r = 1'b0;
reg target_en_r = 1'b0;
reg wr_start_nonce_r = 1'b0;
reg system_ram_dword_we_r = 1'b0;
reg system_ram_dword_we_rr = 1'b0;
reg go_success_r = 1'b0;
reg wr_golden_nonce_r = 1'b0;
reg wr_golden_nonce = 1'b0;
reg set_status_r = 1'b0;
reg set_status = 1'b0;
reg wr_current_nonce = 1'b0;
reg wr_current_nonce_r = 1'b0;
wire [31:0]		status;// = 32'b0
reg go_unsucces_r = 1'b0;
reg ready4hash = 1'b0;
reg target_done_r = 1'b0;
reg hash_cmplted = 1'b0;
reg block_done = 1'b0;
reg target_done = 1'b0;
reg wr_bad_nonce_r = 1'b0;
reg wr_bad_nonce = 1'b0;
//
	assign		status = {20'b0, busy, hash_cmplted, ready4hash, start_stop, hash_frequency};
//
always @ (posedge clk_h)
	begin
		ready4hash <= block_done & target_done;
		if (host_break | m2_ticket2moon | hash_cmplt)
			begin
					block_done <= 1'b0;
					target_done <= 1'b0;
			end
		else if (block_data_en_r) 
			block_done <= 1'b1;
		else if (target_en_r)
			target_done <= 1'b1;
	end
//
always @ (posedge clk_h)
		if (host_break | wr_start_nonce_r | target_done_r )
			hash_cmplted <= 1'b0;
		else if (hash_cmplt)
			hash_cmplted <= 1'b1;

//
always @ (posedge clk_h)
	begin
			if (set_wr_block_adrr)
				system_ram_dword_addr <= 6'h0;
			else if (set_target_adrr)
				system_ram_dword_addr <= 6'h32;
			else if (m2_ticket2moon | hash_cmplt)
				system_ram_dword_addr <= 6'h14;
			else if (set_status)
				system_ram_dword_addr <= 6'h12;
			else if (m1_wr_nonce)
				system_ram_dword_addr <= 6'h1a;
			else if (system_ram_dword_addr_en)
				system_ram_dword_addr <= system_ram_dword_addr + 6'h1;
	end
//		
always @ (posedge clk_h)
	begin
			if (wr_golden_nonce)
				system_ram_dword_data <= current_nonce - 2'b11;
			else if (wr_bad_nonce)
				system_ram_dword_data <= 32'hffff;
			else if (set_status)
				system_ram_dword_data <= status;
			else if (wr_current_nonce)
				system_ram_dword_data <= current_nonce;
	end
		
//
always @ (posedge clk_h)
		sc_sm_state <= sc_sm_state_next;
//
always @(*)		
begin
set_wr_block_adrr_r <= 1'b0;
block_data_en_r <= 1'b0;
set_target_adrr_r <= 1'b0;	
system_ram_dword_addr_en_r <= 1'b0;
target_en_r <= 1'b0;	
wr_start_nonce_r <= 1'b0;
system_ram_dword_we_r <= 1'b0;
go_success_r <= 1'b0;
go_unsucces_r <= 1'b0;
wr_golden_nonce_r <= 1'b0;
target_done_r <= 1'b0;
set_status_r <= 1'b0;
wr_bad_nonce_r <= 1'b0;
wr_current_nonce_r <= 1'b0;
	
			case (sc_sm_state)
							SC_IDLE: //000
								begin
									if (wr_block)
											sc_sm_state_next <= SC_WRBLOCK1;
									else if (set_target)
										begin
											sc_sm_state_next <= SC_SETTARGET1;
										end
									else if (m2_ticket2moon)
										begin
											wr_golden_nonce_r <= 1'b1;
											sc_sm_state_next <= SC_HASHSUCCES;
										end
									else if (hash_cmplt)
										begin
											wr_bad_nonce_r <= 1'b1;
											sc_sm_state_next <= SC_HASHUNSUCCES;
										end
									else if (m1_wr_nonce)
										begin
											wr_current_nonce_r <= 1'b1;
											sc_sm_state_next <= SC_SETCURRENTNONCE;	
										end
									else if (status_go)
											begin
												set_status_r <= 1'b1;
												sc_sm_state_next <= SC_SETSTATUS;
											end
											
									else
										begin
											sc_sm_state_next <= SC_IDLE;
										end
								end
							//
							SC_WRBLOCK1: //001
								begin
										if (uart_cou_dword_en)
											begin
												sc_sm_state_next <= SC_WRBLOCK2;
											end
										else
											begin
												set_wr_block_adrr_r <= 1'b1;
												sc_sm_state_next <= SC_WRBLOCK1;
											end
									end
								//
							SC_WRBLOCK2: //001
								begin
									if (uart_cou_dword_en)
										begin
											system_ram_dword_addr_en_r <= 1'b1;
											block_data_en_r <= 1'b1;
											sc_sm_state_next <= SC_WRBLOCK2;
										end
									else if (link_rx_wr_cmplt)//
										begin
											system_ram_dword_addr_en_r <= 1'b1;
											block_data_en_r <= 1'b1;
											wr_start_nonce_r <= 1'b1;
											sc_sm_state_next <= SC_IDLE;
										end
									else
										begin
											sc_sm_state_next <= SC_WRBLOCK2;
										end
								end
							
							//
							SC_SETTARGET1: // 010
								begin
									if (uart_cou_dword_en)
										begin
											sc_sm_state_next <= SC_SETTARGET2;
										end
									else
										begin
											set_target_adrr_r <= 1'b1;
											sc_sm_state_next <= SC_SETTARGET1;
										end
								end
								//
							SC_SETTARGET2: // 011
								begin
									if (uart_cou_dword_en)
										begin
											target_en_r <= 1'b1;
											system_ram_dword_addr_en_r <= 1'b1;
											sc_sm_state_next <= SC_SETTARGET2;
										end
									else if (link_rx_wr_cmplt)//
										begin
											target_en_r <= 1'b1;
											system_ram_dword_addr_en_r <= 1'b1;
											target_done_r <= 1'b1;
											sc_sm_state_next <= SC_IDLE;
										end
									else
										begin
											sc_sm_state_next <= SC_SETTARGET2;
										end
								end
								//
							SC_HASHSUCCES: // 100
								begin
										go_success_r <= 1'b1;
										system_ram_dword_we_r <= 1'b1;
										sc_sm_state_next <= SC_IDLE;
								end
								//
							SC_HASHUNSUCCES:// 0111
								begin
										go_unsucces_r <= 1'b1;
										system_ram_dword_we_r <= 1'b1;
										sc_sm_state_next <= SC_IDLE;
								end
								//
							SC_SETSTATUS: //1001
								begin
									system_ram_dword_we_r <= 1'b1;
									set_status_r <= 1'b1;
									sc_sm_state_next <= SC_IDLE;
								end
								//
							SC_SETCURRENTNONCE: //1010
								begin
									if (hash_cmplt)
										sc_sm_state_next <= SC_HASHUNSUCCES;
									else
										begin
											system_ram_dword_we_r <= 1'b1;
											sc_sm_state_next <= SC_IDLE;
										end
								end
							
			endcase				




end
//	
always @ (posedge clk_h)
begin
		set_wr_block_adrr <= set_wr_block_adrr_r;
		block_data_en <= block_data_en_r;
		set_target_adrr <= set_target_adrr_r; 
		system_ram_dword_addr_en <= system_ram_dword_addr_en_r;
		target_en <= target_en_r;
		wr_start_nonce <= wr_start_nonce_r;
		system_ram_dword_we_rr <= system_ram_dword_we_r;
		system_ram_dword_we <= system_ram_dword_we_rr;
		wr_golden_nonce <= wr_golden_nonce_r;
		go_success <= go_success_r;
		go_unsucces <= go_unsucces_r;
		set_status <= set_status_r;
		wr_bad_nonce <= wr_bad_nonce_r;
		wr_current_nonce <= wr_current_nonce_r;
		
end		
//


//

		
endmodule		
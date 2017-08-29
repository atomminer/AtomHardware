// 
// recieved byte:
//reboot           		8'h30
//host_break            8'h31   	
//start                 8'h32
//stop                  8'h34 
//wr_block              8'h38
//
//get_signature			8'h49 == I
//read_ubuf					8'h52	 == R
//get_status	         8'h53 == S 
//set_target				8'h54 == T
//set_nonce					8'h4E == N
//get_current_nonce		8'h6e == n
//set_timestamp			8'h57 == W
//
//set_clk					8'h43 == C
//
//

(* preserve *)
module link_rx (
	input clk_25,
	input rx_byte_rsvd,
	input [7:0] rx_byte,
	//
	output reg		reboot = 1'b0,
	output reg		host_break = 1'b0,
	output reg		start = 1'b0,
	output reg		stop = 1'b0,
	output reg		get_signature = 1'b0,
	output reg		read_ubuf = 1'b0,
	output reg		get_status = 1'b0,
	output reg		get_current_nonce = 1'b0,
	//
	output reg		wr_block = 1'b0,
	output reg		set_target = 1'b0,
	output reg		set_timestamp = 1'b0,
	output reg		set_nonce = 1'b0,
	output reg		go_reconfig = 1'b0,
	/// system_ram
				input    wr_block_cmplt,
				input    wr_block_blk_cmplt,
				input    wr_block_target_cmplt,
				//outs
				output reg 			cou_system_ram_byte_addr_en = 1'b0,
				output reg			system_ram_wr_byte = 1'b0,
				output reg			uart_cou_dword_en = 1'b0,
				output reg			cou_dword_res = 1'b0,
				output reg			link_rx_wr_cmplt = 1'b0,
	output 	reg			creeping_trigger = 1'b0
);
//
 localparam		URX_IDLE				= 3'b000,
					URX_POLL				= 3'b001,
					URX_WRBLOCK			= 3'b010,
					URX_WRBLOCK_BLK	= 3'b011,
					URX_WRTARGET		= 3'b100,
					URX_CLK				= 3'b101;

reg [2:0]	rx_sm_state = 3'b0;
reg [2:0]	rx_sm_state_next = 3'b0;
//
reg	set_res = 1'b0;
reg 	[8:0] wdt = 9'b0;// watch dog wait for 1 byte
reg	wdt_en = 1'b0;
reg 	wdt_res = 1'b0;
reg	wdt_down = 1'b0;
reg		sample_command = 1'b0;
reg		system_ram_wr_byte_r = 1'b0;
reg		cou_system_ram_byte_addr_en_r = 1'b0;
reg		set_clk = 1'b0;
reg	[1:0] cou_dword = 2'b0;
reg			cou_dword_en = 1'b0;
reg			uart_cou_dword_en_r = 1'b0;
reg			link_rx_wr_cmplt_r = 1'b0;
//
//
always @ (posedge clk_25)
			if (rx_byte_rsvd)
		creeping_trigger <= rx_byte == 8'h54;
			else
			creeping_trigger <= 1'b0;
//
always @ (posedge clk_25)
	begin
			rx_sm_state <= rx_sm_state_next;
	end
//
always @ (posedge clk_25)
		begin
					reboot <= 1'b0;
					host_break <= 1'b0;
					start <= 1'b0;
					stop <= 1'b0;
					get_signature <= 1'b0;
					read_ubuf <= 1'b0;
					get_status <= 1'b0;
					get_current_nonce <= 1'b0;
		if (sample_command)// 
			begin
					reboot <= rx_byte == 8'h30;					
					host_break <= rx_byte == 8'h31;
					start <= rx_byte == 8'h32;
					stop <= rx_byte == 8'h34;
					get_signature <= rx_byte == 8'h49;
					read_ubuf <= rx_byte == 8'h52;
					get_status <= rx_byte == 8'h53;
					get_current_nonce <= rx_byte == 8'h6e;
			end
		end	   		
//

always @ (posedge clk_25)
			if (set_res)
				begin
					wr_block <= 1'b0;
					set_target <= 1'b0;
					set_nonce <= 1'b0;
					set_timestamp <= 1'b0;
					set_clk <= 1'b0;
				end	
			else if (rx_byte_rsvd & rx_sm_state == 3'b000)//  
				begin
					wr_block <= rx_byte == 8'h38;
					set_target <= rx_byte == 8'h54;
					set_nonce <= rx_byte == 8'h4e;
					set_timestamp <= rx_byte == 8'h57;
					set_clk <= rx_byte == 8'h43;
				end	
// 		
//
always @ (posedge clk_25)
	begin
		system_ram_wr_byte <= system_ram_wr_byte_r;
		cou_system_ram_byte_addr_en <= cou_system_ram_byte_addr_en_r;
		uart_cou_dword_en <= uart_cou_dword_en_r;
		link_rx_wr_cmplt <= link_rx_wr_cmplt_r;
	end 
//
always @ (posedge clk_25)
	begin
		wdt_down <= wdt == 9'h1b0;
		if (wdt_res)
			wdt <= 9'b0;
		else if (wdt_en)
			wdt <= wdt + 9'b1;
	end
//
always @ (posedge clk_25)
		if (cou_dword_res)
			cou_dword <= 2'b0;
		else if (cou_dword_en)
			cou_dword <= cou_dword + 1'b1;			
//
always @ (*)//rx_byte_rsvd or wr_block or wdt_down or rx_sm_state or set_target_cmplt or wr_block_cmplt
begin
	rx_sm_state_next <= 3'b0;
	wdt_en <= 1'b0;
 	wdt_res <= 1'b0;
	sample_command <= 1'b0;
	cou_system_ram_byte_addr_en_r <= 1'b0;
	system_ram_wr_byte_r <= 1'b0;
	set_res <= 1'b0;
	go_reconfig <= 1'b0;
	cou_dword_en <= 1'b0;
	cou_dword_res <= 1'b0;
	uart_cou_dword_en_r <= 1'b0;
	link_rx_wr_cmplt_r <= 1'b0;
	
	
		case (rx_sm_state)
				URX_IDLE: begin//0000
										if (rx_byte_rsvd) 
											begin
												rx_sm_state_next <= URX_POLL; 
											end
										else 				
											begin
												set_res <= 1'b1;
												rx_sm_state_next <= URX_IDLE; 				
											end
							end
					//
				URX_POLL: begin//001
										if (~wr_block & ~ set_target & ~ set_nonce & ~ set_timestamp & ~ set_clk)// 
											begin
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_IDLE;
											end
										else if (wr_block)// 
											begin
												cou_dword_res <= 1'b1;
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK_BLK;//
											end
										else if (set_target)// 
											begin
												cou_dword_res <= 1'b1;
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_WRTARGET;//
											end
										else if (set_nonce)// 
											begin
												cou_dword_res <= 1'b1;
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK;//
											end
										else if (set_timestamp)// 
											begin
												cou_dword_res <= 1'b1;
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK;//
											end
										else if (set_clk)// 
											begin
												sample_command <= 1'b1;
												rx_sm_state_next <= URX_CLK;//
											end
										else
												rx_sm_state_next <= URX_IDLE; 
								end 
							//
					URX_WRBLOCK: begin //010
										if (wdt_down)
											begin
												wdt_res <= 1'b1;
												set_res <= 1'b1;
												rx_sm_state_next <= URX_IDLE;
											end
										else if (wr_block_cmplt)
											begin
												wdt_res <= 1'b1;
												rx_sm_state_next <= URX_IDLE;//
											end
										else if (rx_byte_rsvd)
											begin
												wdt_res <= 1'b1;
												system_ram_wr_byte_r <= 1'b1;
												cou_system_ram_byte_addr_en_r <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK;
											end
										else
											begin	
												set_res <= 1'b1;
												wdt_en <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK;
											end
									end
											//	
			URX_WRBLOCK_BLK: begin //011
										if (wdt_down)
											begin
												wdt_res <= 1'b1;
												set_res <= 1'b1;
												rx_sm_state_next <= URX_IDLE;
											end
										else if (wr_block_blk_cmplt)
											begin
												wdt_res <= 1'b1;
												link_rx_wr_cmplt_r <= 1'b1;
												rx_sm_state_next <= URX_IDLE;//
											end
										else if (rx_byte_rsvd & cou_dword == 2'b11)
											begin
												wdt_res <= 1'b1;
													uart_cou_dword_en_r <= 1'b1;
												cou_dword_en <= 1'b1;
												system_ram_wr_byte_r <= 1'b1;
												cou_system_ram_byte_addr_en_r <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK_BLK;
											end
										else if (rx_byte_rsvd)
											begin
												wdt_res <= 1'b1;
												system_ram_wr_byte_r <= 1'b1;
												cou_dword_en <= 1'b1;
												cou_system_ram_byte_addr_en_r <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK_BLK;
											end
										else
											begin	
												wdt_en <= 1'b1;
												set_res <= 1'b1;
												rx_sm_state_next <= URX_WRBLOCK_BLK;
											end
									end
											//	
			URX_WRTARGET: begin //100
										if (wdt_down)
											begin
												wdt_res <= 1'b1;
												set_res <= 1'b1;
												rx_sm_state_next <= URX_IDLE;
											end
										else if (wr_block_target_cmplt)
											begin
												wdt_res <= 1'b1;
												link_rx_wr_cmplt_r <= 1'b1;
												rx_sm_state_next <= URX_IDLE;//URX_RECOVERY
											end
										else if (rx_byte_rsvd & cou_dword == 2'b11)
											begin
												wdt_res <= 1'b1;
													uart_cou_dword_en_r <= 1'b1;
												cou_dword_en <= 1'b1;
												system_ram_wr_byte_r <= 1'b1;
												cou_system_ram_byte_addr_en_r <= 1'b1;
												rx_sm_state_next <= URX_WRTARGET;
											end
										else if (rx_byte_rsvd )//& cou_dword != 2'b00
											begin
												wdt_res <= 1'b1;
												cou_dword_en <= 1'b1;
												system_ram_wr_byte_r <= 1'b1;
												cou_system_ram_byte_addr_en_r <= 1'b1;
												rx_sm_state_next <= URX_WRTARGET;
											end
										else
											begin	
												wdt_en <= 1'b1;
												set_res <= 1'b1;
												rx_sm_state_next <= URX_WRTARGET;
											end
									end
											//
					URX_CLK: begin //100
										if (wdt_down)
												begin
													wdt_res <= 1'b1;
													set_res <= 1'b1;
													rx_sm_state_next <= URX_IDLE;
												end
										else if (rx_byte_rsvd)
												begin
													wdt_res <= 1'b1;
													go_reconfig <= 1'b1;
													system_ram_wr_byte_r <= 1'b1;
													rx_sm_state_next <= URX_IDLE;
												end
											else
												begin	
													wdt_en <= 1'b1;
													rx_sm_state_next <= URX_CLK;
												end	
									end
											//									
			
	default: 	begin 	rx_sm_state_next <= URX_IDLE; end
	
	endcase
end
//	



endmodule

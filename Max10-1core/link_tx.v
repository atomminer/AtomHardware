    module link_tx (
	input 	clk_25,
	input		host_break,
	input 	start_stop,
	input		get_status,
	input		get_signature,
	input		get_current_nonce,
	input		read_ubuf,
	input		tx_byte_cmplt,
	input		reconfig_ok,
	input		go_success,
	input		go_unsucces,

//
	input		send_tx_cmpl,	

	output reg cou_system_ram_byte_addr_en_tx = 1'b0,
	
	output reg tx_byte_go = 1'b0,
	output reg status_go = 1'b0,
	output reg signature_go = 1'b0,
	output reg current_nonce_go = 1'b0,
	output reg cmpltd_go = 1'b0,
	output reg uncmpltd_go = 1'b0,
	output reg 	read_ubuf_go = 1'b0
	
);
//	
 localparam		UTX_IDLE							= 2'b00,
					UTX_SEND							= 2'b01,
					UTX_SUCCES						= 2'b10;
									
//
reg 		tx_byte_go_r = 1'b0;
reg 		status_go_r = 1'b0;
reg		signature_go_r = 1'b0;
reg		current_nonce_go_r = 1'b0;
reg 		cmpltd_go_r = 1'b0;
reg 		uncmpltd_go_r = 1'b0;
reg 		read_ubuf_go_r = 1'b0;

reg 	[1:0]	 tx_sm_state = 2'b0;
reg 	[1:0]	 tx_sm_state_next = 2'b0;
//
reg 	[8:0] wdt = 9'b0;// watch dog wait for 1 byte
reg	wdt_en = 1'b0;
reg 	wdt_res = 1'b0;
reg	wdt_down = 1'b0;

reg			cou_system_ram_byte_addr_en_tx_r = 1'b0;
reg			go_unsucces_in = 1'b0;
reg			go_succes_in = 1'b0;
reg			go_cmplt_res = 1'b0;
//
always @ (posedge clk_25)
begin
		if (go_cmplt_res)
			go_succes_in <= 1'b0;
		else if (go_success)
			go_succes_in <= 1'b1;
end
//
always @ (posedge clk_25)
begin
		if (go_cmplt_res)
			go_unsucces_in <= 1'b0;
		else if (go_unsucces)
			go_unsucces_in <= 1'b1;
end
always @ (posedge clk_25)
	begin
		wdt_down <= wdt == 9'h12d;
		if (wdt_res)
			wdt <= 9'b0;
		else if (wdt_en)
			wdt <= wdt + 9'b1;
	end
//
always @ (posedge clk_25)
			if (host_break)
			tx_sm_state <= UTX_IDLE;	
			else
			tx_sm_state <= tx_sm_state_next;	 

//
always @ (*)
begin
wdt_en <= 1'b0;
wdt_res <= 1'b0;
status_go_r <= 1'b0;
signature_go_r <= 1'b0;
current_nonce_go_r <= 1'b0;
tx_byte_go_r <= 1'b0;	
cmpltd_go_r <= 1'b0;
uncmpltd_go_r <= 1'b0;
read_ubuf_go_r <= 1'b0;
cou_system_ram_byte_addr_en_tx_r <= 1'b0;
go_cmplt_res <= 1'b0;
							         									
		case (tx_sm_state)
				UTX_IDLE: begin//0000
									if (get_status)
										begin
											status_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											tx_sm_state_next <= UTX_SEND;
										end
									else if (get_signature)
										begin
											signature_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											tx_sm_state_next <= UTX_SEND;
										end
									else if (read_ubuf )
										begin
											read_ubuf_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											tx_sm_state_next <= UTX_SEND;	
										end
									else if (get_current_nonce)
										begin
											current_nonce_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											tx_sm_state_next <= UTX_SEND;	
										end											
									else if (go_succes_in)//
										begin
											cmpltd_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											go_cmplt_res <= 1'b1;
											tx_sm_state_next <= UTX_SEND;//UTX_SUCCES
										end
									else if (go_unsucces_in)// 
										begin
											uncmpltd_go_r <= 1'b1;
											tx_byte_go_r <= 1'b1;
											go_cmplt_res <= 1'b1;
											tx_sm_state_next <= UTX_SEND;//
										end
									
									else
										begin
											tx_sm_state_next <= UTX_IDLE;
										end
							 end	 
									 //
				UTX_SEND: begin // 01
													if (wdt_down)
														begin
															wdt_res <= 1'b1;
															tx_sm_state_next <= UTX_IDLE;
														end
													else if (tx_byte_cmplt & send_tx_cmpl)//  
														begin
															wdt_res <= 1'b1;
															tx_sm_state_next <= UTX_IDLE;//
														end
													else if (tx_byte_cmplt)//  
														begin
															wdt_res <= 1'b1;
															tx_byte_go_r <= 1'b1;
															cou_system_ram_byte_addr_en_tx_r <= 1'b1;
															tx_sm_state_next <= UTX_SEND;//
														end	
													else	
													begin	
														wdt_en <= 1'b1;
														tx_sm_state_next <= UTX_SEND;
													end												
											end
											//
										
		default: 	begin 	tx_sm_state_next <= UTX_IDLE; end										
		endcase
end
//
always @ (posedge clk_25)
begin	
	tx_byte_go <= tx_byte_go_r;
	status_go <= status_go_r;
	read_ubuf_go <= read_ubuf_go_r;
	signature_go <= signature_go_r;
	current_nonce_go <= current_nonce_go_r;
	cmpltd_go <= cmpltd_go_r;
	uncmpltd_go <= uncmpltd_go_r;
	cou_system_ram_byte_addr_en_tx <= cou_system_ram_byte_addr_en_tx_r;
end




endmodule
 				
				

//rx:
//		31 = = host_break
//
//
module uart (

	input	wire		  clk_25,
	output wire		host_break,
	output reg		start_stop = 1'b0,
	output wire		go_reconfig,
	output wire			 reboot,

//rx
		input wire rx,
		
		output [7:0]  rx_byte,
//tx
		input wire 			reconfig_ok,
		input wire [7:0]	system_ram_tx_byte,
		input wire 			go_success,
		input wire 			go_unsucces,
		
		output reg			tx = 1'b0,
//system_ram
		output wire 		set_target,
		output wire 		set_timestamp,
		output wire 		wr_block,
		output wire	[7:0]	system_ram_byte_addr,
		output wire			system_ram_wr_byte,
		output wire			uart_cou_dword_en,
		output wire			cou_dword_res,
		output wire			link_rx_wr_cmplt,
		output wire			status_go,
		
		output wire					creeping_trigger
);
//
//rx

wire	[7:0] rx_data_tetr;
wire 			rx_byte_rsvd; 
wire			get_status;
wire			get_current_nonce;
wire			start;
wire			stop;
wire			wr_target;

//tx
wire			u_tx;
reg 			tx_byte_go = 1'b0;
wire 			link_tx_byte_go;
wire			tx_byte_cmplt;
reg	[7:0]	tx_byte = 1'b0;
wire			tx_active;
//wire			status_go;
wire			read_ubuf_go;
wire			read_ubuf;
wire			current_nonce_go;
wire			cmpltd_go;
wire			uncmpltd_go;
//
//
wire [7:0]	tx_tetr;
wire 				get_signature;
wire				signature_go;
///
reg [7:0]	cou_system_ram_byte_addr = 8'b0;
wire			cou_system_ram_byte_addr_en;
reg			wr_block_target_cmplt = 1'b0;
reg			wr_block_cmplt = 1'b0;
reg wr_block_blk_cmplt = 1'b0;
wire set_nonce;
//
wire	 	cou_system_ram_byte_addr_en_tx;
reg		send_tx_cmpl = 1'b0;

//
//
always @ (posedge clk_25)
	if (stop | go_success | go_unsucces)// | ticket2moon
		start_stop <= 1'b0;
	else if (start)
		start_stop <= 1'b1;
//
always @ (posedge clk_25)
	tx <= u_tx;
//
uart_rx uart_rx 
  (
   .i_Clock(clk_25),
   .i_Rx_Serial(rx),
   .o_Rx_DV(rx_byte_rsvd),
	//
   .o_Rx_Byte(rx_byte)
   );
//
link_rx link_rx
	(
	.clk_25(clk_25),
	.rx_byte_rsvd(rx_byte_rsvd),
	.rx_byte(rx_byte),
//outs
	.reboot(reboot),
	.host_break(host_break),
	.start(start),
	.stop(stop),
	.get_signature(get_signature),
	.read_ubuf(read_ubuf),
	.get_status(get_status),
	.get_current_nonce(get_current_nonce),
			.wr_block(wr_block),
			.set_target(set_target),
			.set_timestamp(set_timestamp),
			.set_nonce(set_nonce),
			.go_reconfig(go_reconfig),
	//// system_ram
				//.set_target_cmplt(set_target_cmplt),
				.wr_block_cmplt(wr_block_cmplt),
				.wr_block_blk_cmplt(wr_block_blk_cmplt),
				.wr_block_target_cmplt(wr_block_target_cmplt),
				//.set_timestamp_cmplt(set_timestamp_cmplt),
				//
					.cou_system_ram_byte_addr_en(cou_system_ram_byte_addr_en),
					.system_ram_wr_byte(system_ram_wr_byte),
					.uart_cou_dword_en(uart_cou_dword_en),
					.cou_dword_res(cou_dword_res),
					.link_rx_wr_cmplt(link_rx_wr_cmplt),
	
	.creeping_trigger(creeping_trigger)
);
//	
assign system_ram_byte_addr = cou_system_ram_byte_addr;
always @ (posedge clk_25)
	if (wr_block | read_ubuf_go)
			cou_system_ram_byte_addr <= 8'b0;
		else if (set_target)
			cou_system_ram_byte_addr <= 8'hc8;
		else if (set_nonce) 
			cou_system_ram_byte_addr <= 8'h2c;
		else if (set_timestamp) 
			cou_system_ram_byte_addr <= 8'h24;
		else if (go_reconfig) 
			cou_system_ram_byte_addr <= 8'h4b;
		//
		else if (status_go)
			cou_system_ram_byte_addr <= 8'h48;
		else if (signature_go)
			cou_system_ram_byte_addr <= 8'h6c;
		else if (current_nonce_go)
			cou_system_ram_byte_addr <= 8'h68;
		else if (cmpltd_go)
			cou_system_ram_byte_addr <= 8'h4c;
		else if (uncmpltd_go)
			cou_system_ram_byte_addr <= 8'h54;	
		
		
	else if (cou_system_ram_byte_addr_en | cou_system_ram_byte_addr_en_tx)
		cou_system_ram_byte_addr <= cou_system_ram_byte_addr + 8'h1;
	//else
		//cou_system_ram_byte_addr <= 8'b0;
//
always @ (posedge clk_25)
	begin
		wr_block_cmplt <= cou_system_ram_byte_addr == 8'h28/*set_timestamp*/ | cou_system_ram_byte_addr == 8'h30/*set_nonce*/;									
		wr_block_blk_cmplt <= cou_system_ram_byte_addr == 8'h30;//wr_block hash2
		wr_block_target_cmplt <= cou_system_ram_byte_addr == 8'he8;/*set_target*/ 
		
		send_tx_cmpl <=  cou_system_ram_byte_addr == 8'h4b/*status*/ | cou_system_ram_byte_addr == 8'h8b/*signature*/ | cou_system_ram_byte_addr == 8'h2f/*nonce*/ | cou_system_ram_byte_addr == 8'h6b/*current_nonce*/ |	cou_system_ram_byte_addr == 8'h53/*golden hash*/ | cou_system_ram_byte_addr == 8'h5b /*uncmplt*/   | cou_system_ram_byte_addr == 8'he7/*endOFtarget[31:0]*/;							
																																		
	end	
//
//
 uart_tx  uart_tx
  (
   .i_Clock(clk_25),
   .i_Tx_DV(tx_byte_go),
   .i_Tx_Byte(tx_byte), 
   .o_Tx_Active(tx_active),
   .o_Tx_Serial(u_tx),
   .o_Tx_Done(tx_byte_cmplt)
   );
//
always @ (posedge clk_25)
begin
	tx_byte <= system_ram_tx_byte;
	tx_byte_go	<= link_tx_byte_go;
end
	
//
link_tx link_tx
	(
	.clk_25(clk_25),
	.host_break(host_break),
	.start_stop(start_stop),
	.get_status(get_status),
	.get_signature(get_signature),
	.get_current_nonce(get_current_nonce),
	.read_ubuf(read_ubuf),
	.tx_byte_cmplt(tx_byte_cmplt),
	.reconfig_ok(reconfig_ok),
	.go_success(go_success),
	.go_unsucces(go_unsucces),

	.send_tx_cmpl(send_tx_cmpl),
	
	// outs
	.cou_system_ram_byte_addr_en_tx(cou_system_ram_byte_addr_en_tx),
	
	
	.tx_byte_go(link_tx_byte_go),
	.status_go(status_go),
	.signature_go(signature_go),
	.current_nonce_go(current_nonce_go),
	.cmpltd_go(cmpltd_go),
	.uncmpltd_go(uncmpltd_go),
	.read_ubuf_go(read_ubuf_go)

);
//
//


endmodule

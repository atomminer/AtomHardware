//clk - N14
// led start/stop - M2
//led ticket2moon - AA5
//uart_rx - A5
//uart_tx - A6

module sha_256_v2 (

	input clk, //50M
//
	input  wire uart_rx,
	output wire uart_tx,
	
	output wire  start_led,
	output reg  clk_h_div = 1'b0
);
//
wire clk_25;
wire clk_h;
wire lock_h;
wire reconfig_ok;
wire go_reconfig;


//m1m2_t0
reg [31:0]			m1_next_nonce_t0 = 32'b0;
reg 					m1_wr_nonce_t0  = 1'b0;
reg [4:0]			m1_header_ram_addr_a_t0  = 5'b0;
reg [4:0]			m1_header_ram_addr_b_t0  = 5'b0;
reg [31:0]			data_from_host_t0  = 32'b0;
reg 					m1_header_ram_wren_a_t0  = 1'b0;
reg 					m1_abc_en_t0  = 1'b0;
reg 					m1_abc_load_t0  = 1'b0;
reg 					m1_wt_reg_en_t0  = 1'b0;
reg 					m1_wt_sw_t0  = 1'b0;
reg [5:0]			m1_k_rom_address_t0 = 6'b0; 
reg 					m1_k_rom_clkh_en_t0  = 1'b0;
reg [3:0]			m2_header_ram_addr_a_t0 = 4'b0; 
reg [3:0]			m2_header_ram_addr_b_t0  = 4'b0;
reg 					m2_header_ram_wren_a_t0  = 1'b0;
reg 					m2_abc_en_t0  = 1'b0;
reg 					m2_abc_load_t0  = 1'b0;
reg 					m2_wt_reg_en_t0  = 1'b0;
reg 					m2_wt_sw_t0  = 1'b0;
reg [5:0]			m2_k_rom_address_t0  = 6'b0;
reg 					m2_k_rom_clkh_en_t0  = 1'b0;
reg 					catch_bits_t0  = 1'b0;	
wire					ticket2moon_t0;		
//						
///////////////////////////////////////////
//	m1_sm
wire 			m1_wr_nonce;
wire 			load_bits;
wire			go_m2;
wire [31:0]		data_from_host;	
				//m1_header_ram_ip
					wire [4:0] 		m1_header_ram_addr_a;
					wire [4:0] 		m1_header_ram_addr_b;
					wire				m1_header_ram_wren_a;
					wire				read_header;			
				//m1_abc_reg_ip		
					wire					m1_abc_en;
					wire	 				m1_abc_load;
				//m1_wt_reg
					wire 				m1_wt_reg_en;		
					wire 				m1_wt_sw;
				//m1_k_rom
					wire [5:0] 	m1_k_rom_address;
					wire 			m1_k_rom_clkh_en;	
//
///////////////////////////////////////////////					
// m2_sm
				//m2_header_ram_ip
					wire [3:0] 	m2_header_ram_addr_a;
					wire [3:0] 	m2_header_ram_addr_b;
					wire			m2_header_ram_wren_a;
				//m2_abc_reg
					wire				m2_abc_en;
					wire				m2_abc_load;
				//m2_wt_reg
					wire				m2_wt_reg_en;
					wire				m2_wt_sw;
				//m2_k_rom_address
					wire  [5:0] 		m2_k_rom_address;
					wire  			m2_k_rom_clkh_en;	
				//m2_target_polling
					wire 			catch_bits;
/////////////////////////////////////////
//
wire	start_stop;
wire host_break;
//
wire		m2_ticket2moon_t0;
//reg	[31:0]	gold_nonce = 32'b0;
reg		hash_cmplt = 1'b0;
//uart
wire [7:0]		rx_byte;
wire [7:0]		system_ram_tx_byte;
wire [7:0]	system_ram_byte_addr;
wire			system_ram_wr_byte;	
wire 			uart_cou_dword_en;
wire [31:0]	system_ram_dword_data;
wire [5:0]	system_ram_dword_addr;	
wire			system_ram_dword_we;	
//
wire	[31:0]	target;
wire				target_en;
reg				m2_target_en_t0;
wire				timestamp_en;
wire	[31:0]	block_data;
wire				block_data_en;
wire	[31:0]	nonce;
wire				set_target;
wire				set_timestamp;
wire				wr_block;
wire				cou_dword_res;
wire				wr_start_nonce;
wire				link_rx_wr_cmplt;
wire				go_success;
wire				go_unsuccess;
wire				busy;
wire 	[7:0]		hash_frequency;
wire				status_go;
reg go_success_uart = 1'b0;
reg go_unsuccess_uart = 1'b0;
reg go_success_uart_h = 1'b0;
reg go_unsuccess_uart_h = 1'b0;
reg uart_cou_dword_en_h_r = 1'b0;
reg uart_cou_dword_en_h_rr = 1'b0;
reg uart_cou_dword_en_h = 1'b0;
reg link_rx_wr_cmplt_h_r = 1'b0;
reg link_rx_wr_cmplt_h_rr = 1'b0;
reg link_rx_wr_cmplt_h = 1'b0;
//
reg [10:0] cou_clk_h_div = 11'b0;
reg cou_clk_h_div_down = 1'b0;

//clk_divider
always @ (posedge clk_h)
	begin
		cou_clk_h_div <= cou_clk_h_div + 1'b1;
		cou_clk_h_div_down <= &cou_clk_h_div;
	end
always @ (posedge clk_h)
		if (cou_clk_h_div_down)
			clk_h_div <= ~clk_h_div;

//

MAXclocking MAXclocking
			(
		.clk(clk), // input clock = 50MGz
		.host_break(host_break),
		.go_reconfig(go_reconfig), // 
		.reqstd_frequency(system_ram_tx_byte),
		//
		.clk_25(clk_25), // uart
		.lock_25(),//lock_25
		.clk_h(clk_h), //soft programmed 25 - 100MGz, default 25MGz
		.lock_h(lock_h),
		.busy(busy),
		.hash_frequency(hash_frequency),
		.reconfig_ok(reconfig_ok)
);
//
//
uart   uart
	(
	.clk_25(clk_25),//
	//outs
	.host_break(host_break),
	.start_stop(start_stop),
	.go_reconfig(go_reconfig),
	.reboot(),
//rx
		.rx(uart_rx),
		//outs	
		.rx_byte(rx_byte),
//tx 
		.reconfig_ok(reconfig_ok),
		.system_ram_tx_byte(system_ram_tx_byte),
		
		.go_success(go_success_uart),
		.go_unsucces(go_unsuccess_uart),
		
		//outs
		.tx(uart_tx), //
//		
//system_ram
		.set_target(set_target),
		.set_timestamp(set_timestamp),
		.wr_block(wr_block),
		.system_ram_byte_addr(system_ram_byte_addr),
		.system_ram_wr_byte(system_ram_wr_byte),
		.uart_cou_dword_en(uart_cou_dword_en),
		.cou_dword_res(cou_dword_res),
		.link_rx_wr_cmplt(link_rx_wr_cmplt),
		.status_go(status_go),
		.creeping_trigger()
);	
//
//crossclock transfer from clk_uart 2 clk_h
always @ ( posedge clk_h)
		if (go_success_uart | go_unsuccess_uart)
			begin
			go_success_uart_h <= 1'b0;
			go_unsuccess_uart_h <= 1'b0;
			end
		else if (go_success)
				go_success_uart_h <= 1'b1;
			else if (go_unsuccess)
				go_unsuccess_uart_h <= 1'b1;
//
always @ ( posedge clk_25)
	begin
		go_success_uart <= go_success_uart_h;
		go_unsuccess_uart <= go_unsuccess_uart_h;
	end
//
//
//crossclock transfer from clk_h 2 clk_uart
always @ (posedge clk_h)
	begin
		uart_cou_dword_en_h_r <= uart_cou_dword_en;
		uart_cou_dword_en_h_rr <= uart_cou_dword_en_h_r;
		uart_cou_dword_en_h <=  ~uart_cou_dword_en_h_r & uart_cou_dword_en_h_rr;
		//
		link_rx_wr_cmplt_h_r <= link_rx_wr_cmplt;
		link_rx_wr_cmplt_h_rr <= link_rx_wr_cmplt_h_r;
		link_rx_wr_cmplt_h <= ~link_rx_wr_cmplt_h_r & link_rx_wr_cmplt_h_rr;
	end
//
//
system_control system_control(
.clk_h(clk_h),
.host_break(host_break),
.go_reconfig(go_reconfig),
.start_stop(start_stop),
.hash_frequency(hash_frequency),
.reconfig_ok(reconfig_ok),
.busy(busy),
.status_go(status_go),
//
.uart_cou_dword_en(uart_cou_dword_en_h),
.wr_block(wr_block),
.set_target(set_target),
.set_timestamp(set_timestamp),
.set_nonce(1'b0),
.cou_dword_res(cou_dword_res),
.link_rx_wr_cmplt(link_rx_wr_cmplt_h),
//
.data_from_host(data_from_host),
//
.m2_ticket2moon(m2_ticket2moon_t0),
.current_nonce( m1_next_nonce_t0),
.hash_cmplt(hash_cmplt),
.m1_wr_nonce(m1_wr_nonce_t0),
//
.system_ram_dword_addr(system_ram_dword_addr),
.system_ram_dword_data(system_ram_dword_data),
.system_ram_dword_we(system_ram_dword_we),
//
.target_en(target_en),
//.timestamp_en(timestamp_en),
.block_data_en(block_data_en),
.wr_start_nonce(wr_start_nonce),
//
.go_success(go_success),
.go_unsucces(go_unsuccess)
			

	);
//					
system_ram	system_ram  (
	.address_a ( system_ram_dword_addr ),//[5:0]
	.address_b ( system_ram_byte_addr ),//[7:0]
	.clock_a ( clk_h ),
	.clock_b ( clk_25 ),
	.data_a ( system_ram_dword_data ),//[31:0]
	.data_b ( rx_byte ),//[7:0]
	.wren_a ( system_ram_dword_we ),//wren_a_sig
	.wren_b ( system_ram_wr_byte ),
	.q_a ( data_from_host ),//[31:0]
	.q_b ( system_ram_tx_byte )//[7:0]
	);				
//			
assign start_led = ~start_stop;		
		//assign 	target	= 256'h248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1;//protocol value	
		//	assign 	target	= 256'hF29DD364D670CC4930257186A7C88F1CBCE903BD7BBC9793C8730D3D72538231;//vi model
		//assign 	target	= 256'h0000000000000000b0f08ec6a3d1e84994498ecf993a9981f57982cfdb66c443;
		//assign 	target	= 256'h0000000000000000c68ef0b049f8d1a3cf8e499481993a99cf8279f543c466db;
//
	m1_sm m1_sm(
					.clk_h(clk_h), 
					.host_break(host_break),
					.lock(lock_h),
					.block_data_en(block_data_en),
					.header_rdy( block_data_en  ),//start_stop
					.start_stop(start_stop),
//outputs					
					.m1_header_ram_wren_a(m1_header_ram_wren_a),
					.load_bits(load_bits),
					.m1_abc_load_r(m1_abc_load),
					.m1_abc_en_r(m1_abc_en),
					.m1_wt_reg_en(m1_wt_reg_en),
					.m1_wt_sw(m1_wt_sw),
					.m1_wr_nonce(m1_wr_nonce),
					.m1_header_ram_addr_a(m1_header_ram_addr_a),
					.m1_header_ram_addr_b(m1_header_ram_addr_b),
					//
					.m1_k_rom_address(m1_k_rom_address),
					.m1_k_rom_clkh_en(m1_k_rom_clkh_en),
					.go_m2(go_m2)
					);
//
	m2_sm m2_sm(
					.clk_h(clk_h),
					.host_break(host_break),
					.start_stop (start_stop),
					.go_m2(go_m2),
	//
					.m2_header_ram_wren_a(m2_header_ram_wren_a),
					.m2_abc_load(m2_abc_load),
					.m2_abc_en(m2_abc_en),
					.m2_wt_reg_en(m2_wt_reg_en),
					.m2_wt_sw(m2_wt_sw),
//
					.m2_header_ram_addr_a(m2_header_ram_addr_a),
					.m2_header_ram_addr_b(m2_header_ram_addr_b),
					.m2_k_rom_address(m2_k_rom_address),
					.m2_k_rom_clkh_en(m2_k_rom_clkh_en),
					.catch_bits(catch_bits)
					);		
//											
//core sha256(sha256(header)) 0-s thread
always @ (posedge clk_h)
		if (wr_start_nonce)
			begin
				m1_next_nonce_t0 <= {data_from_host[7:0],data_from_host[15:8],data_from_host[23:16],data_from_host[31:24]};//32'hccad1600;//ccad165732'hffffffff;// - for battle64656667
			end
		else if (m1_wr_nonce_t0)//
			begin
				m1_next_nonce_t0 <= m1_next_nonce_t0 + 32'h1;//32'hccad1657;
			end
//	
always @ (posedge clk_h)
		if (host_break | ~ start_stop)
			hash_cmplt <= 1'b0;
		else
			hash_cmplt <= m1_next_nonce_t0 ==  &m1_next_nonce_t0 & m1_wr_nonce_t0;// for battle - &m1_next_nonce_t0 & m1_wr_nonce_t0 & m1_wr_nonce_t1 so on;
//			
			always @ (posedge clk_h)
			begin
			//m2_wr_nonce_t0 <= m2_wr_nonce;
			m1_wr_nonce_t0 <= m1_wr_nonce;
			data_from_host_t0 <= {data_from_host[7:0],data_from_host[15:8],data_from_host[23:16],data_from_host[31:24]};//data_from_host;
			m1_header_ram_addr_a_t0 <= m1_header_ram_addr_a;
			m1_header_ram_addr_b_t0 <= m1_header_ram_addr_b;	
			m1_header_ram_wren_a_t0 <= m1_header_ram_wren_a;
			m1_abc_en_t0 <= m1_abc_en;
			m1_abc_load_t0 <= m1_abc_load;
			m1_wt_reg_en_t0 <= m1_wt_reg_en; 
			m1_wt_sw_t0 <= m1_wt_sw;
			m1_k_rom_address_t0 <= m1_k_rom_address;
			m1_k_rom_clkh_en_t0 <= m1_k_rom_clkh_en;
			
			m2_target_en_t0 <= target_en;
			m2_header_ram_addr_a_t0 <= m2_header_ram_addr_a;
			m2_header_ram_addr_b_t0 <= m2_header_ram_addr_b;
			m2_header_ram_wren_a_t0 <= m2_header_ram_wren_a;
			m2_abc_en_t0 <= m2_abc_en;
			m2_abc_load_t0 <= m2_abc_load;
			//m2_rom_init_clk_en_t0 <= m2_rom_init_clk_en;
			m2_wt_reg_en_t0 <= m2_wt_reg_en;
			m2_wt_sw_t0 <= 	m2_wt_sw;
			m2_k_rom_address_t0 <= m2_k_rom_address;
			m2_k_rom_clkh_en_t0 <= m2_k_rom_clkh_en;
			catch_bits_t0 <= catch_bits;
			end

	m1m2 m1m2_t0 (			
					.clk_h(clk_h),			
/////////////////////////////////// m1
					.m1_next_nonce(m1_next_nonce_t0),
					.m1_wr_nonce(m1_wr_nonce_t0),//		
//m1_header_ram_ip
		.m1_header_ram_addr_a(m1_header_ram_addr_a_t0),
		.m1_header_ram_addr_b(m1_header_ram_addr_b_t0),
		.data_from_host(data_from_host_t0),
		.m1_header_ram_wren_a(m1_header_ram_wren_a_t0),
//m1_abc_reg_ip		
		.m1_abc_en(m1_abc_en_t0),
		.m1_abc_load(m1_abc_load_t0),
//m1_wt_reg
		.m1_wt_reg_en(m1_wt_reg_en_t0),		
		.m1_wt_sw(m1_wt_sw_t0),			
//m1_k_rom
		.m1_k_rom_address(m1_k_rom_address_t0),
		.m1_k_rom_clkh_en(m1_k_rom_clkh_en_t0),	
//
////////////////////////////////////m2
		.m2_target_en_t0 (m2_target_en_t0),
//m2_header_ram_ip
		.m2_header_ram_addr_a(m2_header_ram_addr_a_t0),
		.m2_header_ram_addr_b(m2_header_ram_addr_b_t0),
		.m2_header_ram_wren(m2_header_ram_wren_a_t0),
//
//m2_abc_reg
		.m2_abc_en(m2_abc_en_t0),
		.m2_abc_load(m2_abc_load_t0),
//
//m2_wt_reg
		.m2_wt_reg_en(m2_wt_reg_en_t0),
		.m2_wt_sw(m2_wt_sw_t0),
//
//m2_k_rom_address
		.m2_k_rom_address(m2_k_rom_address_t0),
		.m2_k_rom_clkh_en(m2_k_rom_clkh_en_t0),
// 
//m2_target_polling
		.catch_bits(catch_bits_t0),
		.host_break(host_break),
//
		.m2_ticket2moon(m2_ticket2moon_t0)
				);


endmodule
	
					
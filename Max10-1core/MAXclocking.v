//
//1-st PLL clocks UART, reconfig PLL_h. No reconfig
//2-nd PLL clocks SHA256, reconfigable (25 - 120)MGz
//
//reqstd_frequency from soft from 1 - 96. (reqstd_frequency*14'h90-1'b1) - start address corresponding MIF 
//
module MAXclocking (
input clk, // input clock = 50MGz
input host_break,
input go_reconfig, // 
input [7:0] reqstd_frequency,
//
output clk_25, // uart
output lock_25,
output clk_h, //soft programmed 25 thru 120MGz, default 25MGz
output lock_h,
output  reg busy = 1'b0,
output  reg [7:0] hash_frequency = 8'b1,
output  reg reconfig_ok = 1'b0



);
//
localparam	RECONFIG_IDLE 				= 4'b0000,
				RECONFIG_SETADRROM		= 4'b0001,
				RECONFIG_SETADRROMWAIT 	= 4'b0010,
				RECONFIG_SCANDATA0		= 4'b0011,
				RECONFIG_SCANDATAWAIT	= 4'b0100,
				RECONFIG_SCANDATA1		= 4'b0101,
				RECONFIG_SCANDATAWAIT1	= 4'b0110,
				RECONFIG_SCANDATA2 		= 4'b0111,
				RECONFIG_UPDATE 			= 4'b1000,
				RECONFIG_DONE 				= 4'b1001,
				RECONFIG_RES 				= 4'b1010,
				RECONFIG_LOCK 				= 4'b1011;
							
//
wire clk_50;
wire 	scandata;
wire  scandone;
reg 	configupdate = 1'b0;
reg 	scanclkena = 1'b0;
reg	areset = 1'b0;
reg  [13:0] clocking_rom_addr = 14'h0;
reg [3:0] reconfig_sm = 4'b0;
reg	go_reconfig_r = 1'b0;
reg	go_reconfig_rr = 1'b0;
reg	[5:0]	cou_scan = 6'h0;
reg	[2:0] 	cou_scan_blk = 3'b0;
reg host_break_was = 1'b0;
reg hash_frequency_en = 1'b0;

wire	scandataout;
//
always @ (posedge clk_25)
	if (host_break)
		host_break_was <= 1'b1;

always @ (posedge clk_25)
			if (host_break & ~host_break_was)
				hash_frequency <= 8'b1;
			else if (hash_frequency_en)
				hash_frequency <= reqstd_frequency;
				
//
always @ (posedge clk_25)
	begin
			go_reconfig_rr <= go_reconfig;
			go_reconfig_r <= go_reconfig_rr;
	end
//
always @ (posedge clk_25)
	begin
		case (reconfig_sm)
			RECONFIG_IDLE:
						begin
							if (go_reconfig_r)
								begin
									busy <= 1'b1;
									reconfig_sm <= RECONFIG_SETADRROM;
								end
							else 
									begin
									busy <= 1'b0;
									cou_scan <= 6'h0;
									cou_scan_blk <= 2'h0;
									reconfig_ok <= 1'b0;
									reconfig_sm <= RECONFIG_IDLE;	
									end
						end
						//
			RECONFIG_SETADRROM:
						begin
								hash_frequency_en <= 1'b1;
								clocking_rom_addr <= reqstd_frequency * 14'h90 - 1'b1;
								reconfig_sm <= RECONFIG_SETADRROMWAIT;
						end
							//
			RECONFIG_SETADRROMWAIT:
						begin	
							hash_frequency_en <= 1'b0;
							scanclkena <= 1'b1;
							cou_scan <= 6'h0;
							clocking_rom_addr <= clocking_rom_addr - 1'b1;
							reconfig_sm <= RECONFIG_SCANDATA0;
						end
							//
			RECONFIG_SCANDATA0:
						begin
							if (cou_scan == 6'h11)
								begin
									scanclkena <= 1'b0;
									reconfig_sm <= RECONFIG_SCANDATAWAIT;							
								end
							else
								begin
									scanclkena <= 1'b1;
									cou_scan <= cou_scan + 1'b1;
 									clocking_rom_addr <= clocking_rom_addr - 1'b1;
									reconfig_sm <= RECONFIG_SCANDATA0;
								end				
						end
								//
				RECONFIG_SCANDATAWAIT:
						begin
							if (cou_scan_blk == 3'h4)
								begin
									cou_scan_blk <= 3'h0;
									reconfig_sm <= RECONFIG_SCANDATAWAIT1;
								end
							else
								begin	
									cou_scan_blk <= cou_scan_blk + 1'b1;
									cou_scan <= 6'h0;
									reconfig_sm <= RECONFIG_SCANDATA1;
								end	
						end
							//
				RECONFIG_SCANDATA1://0101
						begin
							if (cou_scan == 6'h12)
								begin
									scanclkena <= 1'b0;
									reconfig_sm <= RECONFIG_SCANDATAWAIT;							
								end
							else
								begin
									scanclkena <= 1'b1;
									cou_scan <= cou_scan + 1'b1;
 									clocking_rom_addr <= clocking_rom_addr - 1'b1;
									reconfig_sm <= RECONFIG_SCANDATA1;
								end				
						end
								//				
			RECONFIG_SCANDATAWAIT1://0110
								begin
									cou_scan_blk <= cou_scan_blk + 1'b1;
									cou_scan <= 6'h0;
									reconfig_sm <= RECONFIG_SCANDATA2;
								end						
							//
			RECONFIG_SCANDATA2://0111
						begin
								if (cou_scan == 6'h37)
									begin
										scanclkena <= 1'b0;
										reconfig_sm <= RECONFIG_UPDATE;//
									end	
								else
									begin
										scanclkena <= 1'b1;
										cou_scan <= cou_scan + 1'b1;
										clocking_rom_addr <= clocking_rom_addr - 1'b1;
										reconfig_sm <= RECONFIG_SCANDATA2;
									end						
						end
						//
			RECONFIG_UPDATE://1000
						begin
								configupdate <= 1'b1;
								reconfig_sm <= RECONFIG_DONE;
						end
						//
			RECONFIG_DONE://1001
						begin
								if (scandone)
									reconfig_sm <= RECONFIG_RES;
								else
									begin
										configupdate <= 1'b0;
										reconfig_sm <= RECONFIG_DONE;	
									end
						end
						//
			RECONFIG_RES://1010
						begin
								areset <= 1'b1;
								reconfig_sm <= RECONFIG_LOCK;
						end
						//
			RECONFIG_LOCK://1011
						begin
							if (lock_h)
								begin
								areset <= 1'b0;
								reconfig_ok <= 1'b1;
								reconfig_sm <= RECONFIG_IDLE;
								end
							else
								begin
								areset <= 1'b0;
								reconfig_sm <= RECONFIG_LOCK;
								end
						end
						//
				 default :
							reconfig_sm <= RECONFIG_IDLE;
			endcase
end			
//
//
uart_clocking	uart_clocking (
	.areset ( 1'b0 ),
	.inclk0 ( clk ),
	.c0 ( clk_25 ),
	.c1 (clk_50),
	.locked ( lock_25 )
	);
 //
//
sha_clocking	sha_clocking (
	.areset ( ~lock_25 | areset),
	.configupdate ( configupdate ),
	.inclk0 ( clk_50 ),
	.scanclk ( clk_25 ),
	.scanclkena ( scanclkena ),
	.scandata ( scandata ),
	.c0 ( clk_h ),
	.locked ( lock_h ),
	.scandataout ( scandataout ),
	.scandone ( scandone )
	);
//
clocking_rom25_120	clocking_rom25_120_inst (
	.address ( clocking_rom_addr ),
	.clock ( clk_25 ),
	.q ( scandata )
	);
//
endmodule

//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
//435 for 50M    or
//for 3000000 baud UART & 50M clk  => CLKS_PER_BIT is 50000000/3000000 = 16.(6) = 17
//
//
//for 921600 baud UART & 25M clk  => CLKS_PER_BIT is 25000000/921600 = 27.126736(1) = 27

module uart_rx 
  #(parameter CLKS_PER_BIT = 27)// 9'h1b3435
  (
   input        i_Clock,
   input        i_Rx_Serial,
   output reg      o_Rx_DV = 1'b0,  //strob recieved byte
   output reg [7:0] o_Rx_Byte = 8'b0 //recieved byte
   );

  localparam  s_IDLE         = 3'b000;
  localparam s_RX_START_BIT = 3'b001;
  localparam s_RX_DATA_BITS = 3'b010;
  localparam s_RX_STOP_BIT  = 3'b011;
  localparam s_CLEANUP      = 3'b100;

  reg           r_Rx_Data_R = 1'b1;
  reg           r_Rx_Data   = 1'b1;

  reg [4:0]     r_Clock_Count = 5'b0;
  reg [2:0]     r_Bit_Index   = 3'b0; //8 bits total
  reg [7:0]     r_Rx_Byte     = 8'b0;
  reg           r_Rx_DV       = 1'b0;
  reg [2:0]     r_SM_Main     = 3'b0;

  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial;
      r_Rx_Data   <= r_Rx_Data_R;
    end


  // Purpose: Control RX state machine
  always @(posedge i_Clock)
    begin

      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0;
            r_Clock_Count <= 5'b0;
            r_Bit_Index   <= 3'b0;

            if (r_Rx_Data == 1'b0)          // Start bit detected
              r_SM_Main <= s_RX_START_BIT;
            else
              r_SM_Main <= s_IDLE;
          end

        // Check middle of start bit to make sure it's still low
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (r_Rx_Data == 1'b0)
                  begin
                    r_Clock_Count <= 5'b0;  // reset counter, found the middle
                    r_SM_Main     <= s_RX_DATA_BITS;
                  end
                else
                  r_SM_Main <= s_IDLE;
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
                r_SM_Main     <= s_RX_START_BIT;
              end
          end // case: s_RX_START_BIT


        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
                r_SM_Main     <= s_RX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count          <= 5'b0;
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;

                // Check if we have received all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1'b1;
                    r_SM_Main   <= s_RX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 1'b0;
						  
                    r_SM_Main   <= s_RX_STOP_BIT;
                  end
              end
          end // case: s_RX_DATA_BITS
	
	
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BIT :
          begin
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
	        r_SM_Main     <= s_RX_STOP_BIT;
              end
            else
              begin
	        r_Rx_DV       <= 1'b0;
                r_Clock_Count <= 5'b0;
                r_SM_Main     <= s_CLEANUP;
end
          end // case: s_RX_STOP_BIT
	

        // Stay here 1 clock
        s_CLEANUP :
          begin
//					 if (r_Clock_Count < CLKS_PER_BIT-1)
//						  begin
//								r_Rx_DV   <= 1'b0;
//								r_Clock_Count <= r_Clock_Count + 1'b1;
//								r_SM_Main     <= s_CLEANUP;
//						  end
//						else
							begin
							
								r_Clock_Count <= 5'b0;
								r_SM_Main <= s_IDLE;
								r_Rx_DV   <= 1'b1;
							end
				end

        default :
          r_SM_Main <= s_IDLE;

      endcase
    end    
//
 always @(posedge i_Clock)
	begin
				o_Rx_DV   <= r_Rx_DV;
				o_Rx_Byte <= r_Rx_Byte;
	end			
 
 
 // assign o_Rx_DV   = r_Rx_DV;
  //assign o_Rx_Byte = r_Rx_Byte;

endmodule // uart_rx


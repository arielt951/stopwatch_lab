`timescale 1ns / 10ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: Tel Aviv University
//// Engineer: Ariel Turnowski & Ofek Goshen
//// 
//// Create Date: 04/23/2025 03:25:13 PM
//// Module Name: Ps2_Interface
////////////////////////////////////////////////////////////////////////////////////
module Ps2_Interface(
    input PS2Clk,
    input rstn,
    input PS2Data,
    output reg [7:0] scancode,
    output reg keyPressed
    );

    reg [21:0] shift_reg; 
    reg [3:0 ] bit_count;
    reg [7:0 ] last_code;
    reg got_f0; // Flag to track the break code

    // Process everything on the falling edge to avoid dead-clock issues
    always @(negedge PS2Clk or negedge rstn) begin
        if (!rstn) begin
            shift_reg  <= 22'd0;
            bit_count  <= 4'd0 ;
            scancode   <= 8'd0 ;
            keyPressed <= 1'b0 ;
            last_code  <= 8'd0 ;
            got_f0     <= 1'b0 ;
        end else begin
            // Shift data in (MSB first mathematically, but PS2 sends LSB first)
            // By shifting right, the oldest bits move to the lower indices.
            shift_reg <= {PS2Data, shift_reg[21:1]};
            keyPressed <= 1'b0; // Default state is 0 to ensure it's only a single-cycle pulse
            
            if (bit_count == 4'd10) begin // 11th edge (0-10)
                bit_count <= 0;
                
                // At this exact moment (the 11th falling edge):
                // PS2Data holds the Stop Bit
                // shift_reg[21] holds the Parity Bit
                // shift_reg[20:13] holds the 8 Data Bits
                // shift_reg[12] holds the Start Bit
                
                // Validate Packet: Stop=1, Start=0, Odd Parity
                if (PS2Data == 1'b1 && shift_reg[12] == 1'b0 && (^{shift_reg[21:13]} == 1'b1)) begin
                    
                    if (shift_reg[20:13] == 8'hF0) begin
                        // Break code received: key is being released
                        got_f0 <= 1'b1;
                    end 
                    else if (shift_reg[20:13] == 8'hE0) begin
                        // Extended key prefix: ignore it completely
                    end 
                    else begin
                        if (got_f0) begin
                            // This is the scan code of the released key. 
                            // Reset state so it can be pressed again later.
                            last_code <= 8'd0; 
                            got_f0    <= 1'b0;

                        end 
                        else if (shift_reg[20:13] != last_code) begin
                            // New make-code received
                            scancode <= shift_reg[20:13];
                            keyPressed <= 1'b1;
                            last_code <= shift_reg[20:13]; // Save to prevent repeat pulses
                        end
                    end
                end
            end else begin
                bit_count <= bit_count + 1;
            end
        end
    end

endmodule
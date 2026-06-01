`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Ariel Turnowski & Ofek Goshen
// 
// Create Date:     11/12/2018 08:59:38 PM
// Design Name:     EE3 lab1
// Module Name:     Seg_7_Display 
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     This module translates the input vector "x" into the 
//                  appropriate signals to be fed into the 4-digit-7seg 
//                  component on the Basys3 board:
//                      a_to_g[6:0] - the 7 segments' toggles
//                      an[3:0] - the 4 common anodes of the 4 digits of the display
//                      dp - a dot toggle of every digit (kind of an 8th segment...)
//                  The digits are generated in a cyclic repetition, very fast, 
//                  such that the human eye can't see these changes and an 
//                  impression of constant 4 digits is formed.
//
// Dependencies:    None
//
// Revision:        5.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Seg_7_Display(
    input [15:0] x,   
    input clk,      
    input clr,       
    output reg [6:0] a_to_g, 
    output reg [3:0] an,     
    output wire dp          
);

    wire [1:0] digit_select;
    reg [3:0] digit;

    // For 100MHz clock
    reg [19:0] clkdiv = 20'b0;
    assign digit_select = clkdiv[19:18];  // this effectively generates the frequency division, since these bits are toggled every 2^18 clock cycles
                              // which correspond to every 2.62144 miliseconds (digit period), and ~10ms refresh period of the whole 4-digit screen.

    // Decimal point control
    reg dp_temp;
    assign dp = dp_temp;

    // Digit selection logic
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            clkdiv <= 20'b0;
            digit <= 4'b0;
        end else begin
            clkdiv <= clkdiv + 1;
            case (digit_select)
                2'b00: digit <= x[3:0];     // Rightmost digit
                2'b01: digit <= x[7:4];
                2'b10: digit <= 4'b0000;  
                2'b11: digit <= 4'b0000;
            endcase
        end
    end

    // 7-segment decoder
    always @(*) begin
        dp_temp = 1'b1; // Default: DP off
        case (digit)
            4'h0: a_to_g = 7'b1000000;  // 0
            4'h1: a_to_g = 7'b1111001;  // 1
            4'h2: a_to_g = 7'b0100100;  // 2
            4'h3: a_to_g = 7'b0110000;  // 3
            4'h4: a_to_g = 7'b0011001;  // 4
            4'h5: a_to_g = 7'b0010010;  // 5
            4'h6: a_to_g = 7'b0000010;  // 6
            4'h7: a_to_g = 7'b1111000;  // 7
            4'h8: a_to_g = 7'b0000000;  // 8
            4'h9: a_to_g = 7'b0010000;  // 9
            4'hA: a_to_g = 7'b0001000;  // A
            4'hB: begin a_to_g = 7'b0000000; dp_temp = 1'b0; end // B with DP
            4'hC: a_to_g = 7'b1000110;  // C
            4'hD: begin a_to_g = 7'b1000000; dp_temp = 1'b0; end // D with DP
            4'hE: a_to_g = 7'b0000110;  // E
            4'hF: a_to_g = 7'b0001110;  // F
            default: a_to_g = 7'b1111111;  // Turn off if invalid
        endcase
    end

    // Anode control (digit enable)
    always @(*) begin
        an = 4'b1111;       // Initially disable all digits
        if (digit_select == 2'b00 || digit_select == 2'b01) begin
        an[digit_select] = 1'b0; // Enable the selected digit
        end
    end
endmodule
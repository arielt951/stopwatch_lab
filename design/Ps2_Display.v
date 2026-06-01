`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Tel Aviv University
// Engineer: Ariel Turnowski & Ofek Goshen
// 
// Create Date: 04/23/2025 04:12:17 PM
// Design Name: 
// Module Name: Ps2_Display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Ps2_Display(
    input wire clk,
    input wire rstn,
    input wire keyPressed,
    input wire [7:0] scancode,
    output wire [6:0] seg,
    output wire [3:0] an,
    output wire dp,
    output reg led
);

    // Internal register for the display input
    reg [15:0] x;
    
    // LED control: simple pulse timer
    reg [23:0] led_counter;

    // Instantiate the 7-segment display 
    Seg_7_Display display_unit (
        //inputs
        .x(x),
        .clk(clk),
        .clr(~rstn),   // clr is active-high while rstn is active-low
        .a_to_g(seg),
        .an(an),
        .dp(dp)
    );

    // Latch scancode into the display when keyPressed
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            x <= 16'h0000; 
        end else if (keyPressed) begin
            x[3:0]   <= scancode[3:0];   
            x[7:4]   <= scancode[7:4];  
            x[15:8]  <= 8'h00;           // Turn off the two leftmost digits
        end
    end

    // LED strobe logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            led <= 1'b0;
            led_counter <= 24'd0;
        end else if (keyPressed) begin
            led <= 1'b1;
            led_counter <= 24'd10000000; // Keep LED on for about 10ms 
        end else if (led_counter != 0) begin
            led_counter <= led_counter - 1;
            if (led_counter == 1)
                led <= 1'b0;
        end
    end

endmodule
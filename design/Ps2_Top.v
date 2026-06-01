`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Tel Aviv University
// Engineer: Ariel Turnowski & Ofek Goshen
// 
// Create Date: 04/23/2025 03:24:25 PM
// Design Name: 
// Module Name: Ps2_Top
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
module Ps2_Top(
    input clk,
    input reset,
    input PS2Clk,
    input PS2Data,
    output [6:0] seg,
    output [3:0] an,
    output wire dp,
    output led
    );
    
    wire keyPressed_unstable;
    wire [7:0] scancode_unstable;
    reg keyPressed_stable;
    reg [7:0] scancode_stable;
    wire reset_stable;
    
    always @(posedge clk)
     begin
        keyPressed_stable <= keyPressed_unstable;
        scancode_stable <= scancode_unstable; 
     end
    
    Ps2_Interface interface(
                            .rstn(~reset_stable), 
                            .PS2Clk(PS2Clk), 
                            .PS2Data(PS2Data), 
                            .keyPressed(keyPressed_unstable), 
                            .scancode(scancode_unstable));

    Ps2_Display display(
        .clk(clk), 
        .rstn(~reset_stable), 
        .keyPressed(keyPressed_stable), 
        .scancode(scancode_stable), 
        .seg(seg), 
        .an(an), 
        .dp(dp), 
        .led(led));
        
    Debouncer rst_debouncer(
        .clk(clk), 
        .input_unstable(reset), 
        .output_stable(reset_stable));
    
endmodule

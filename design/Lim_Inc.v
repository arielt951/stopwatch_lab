`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University       
// Engineer:        Yuval Horowitz and Ron Amrani
// Create Date:     05/05/2019 00:16 AM
// Design Name:     EE3 lab1
// Module Name:     Lim_Inc
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Incrementor modulo L, where the input a is *saturated* at L 
//                  If a+ci>L, then the output will be s=0,co=1 anyway.
// 
// Dependencies:    Compadder
// 
// Revision:        3.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Lim_Inc(a, ci, sum, co);
    parameter L = 11;
    
    // Calculate required bits N = ceil(log2(L))
    localparam N = $clog2(L); 
    input [N-1:0] a;
    input ci;
    output reg [N-1:0] sum; // "reg" because we use always block (or wire + assign)
    output reg co;

    // Internal wires for the raw addition
    wire [N-1:0] raw_sum;
    wire raw_co; // The carry out from the adder itself (rarely used if N is large enough)

    // 1. INSTANTIATE CSA
    // We treat 'ci' as the number to add. Since CSA takes two N-bit numbers,
    // we connect input 'b' to 0. The carry-in port of the CSA actually does the +1 logic.
    CSA #(.N(N)) adder_inst (
        .a(a),
        .b({N{1'b0}}), // Connect Input B to zero
        .ci(ci),       // Connect ci to the carry-in of the adder
        .sum(raw_sum),
        .co(raw_co)
    );

    // 2. LOGIC (Compare and Select)
    always @(*) begin
        // Check if we hit the limit L
        // Note: We must also check raw_co in case L is very large (full range)
        if (raw_sum >= L || raw_co == 1) begin
            sum = {N{1'b0}}; // Reset to 0
            co = 1'b1;       // Signal overflow
        end else begin
            sum = raw_sum;   // Pass the calculated value
            co = 1'b0;       // No overflow
        end
    end

endmodule

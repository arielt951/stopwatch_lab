`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Yuval Horowitz and Ron Amrani
// 
// Create Date:     05/05/2019 02:59:38 AM
// Design Name:     EE3 lab1
// Module Name:     Debouncer
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices: 
// Tool versions: 
// Description:     receives an unstable (toggling) digital signal as an input
//                  outputs a single cycle high (1) pulse upon receiving 2**(COUNTER_BITS-1) more ones than zeros.
//                  This creates a hysteresis phenomenon, robust to toggling.
//              
//                  This module should be used to process a normally-off signal and to catch its long lasting "1" period and
//                  shrinking them into a single cycle "1".
//
// Dependencies:    None
//
// Revision:        3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Debouncer(clk, input_unstable, output_stable);
   input clk, input_unstable;
   output reg output_stable;
   
   parameter COUNTER_BITS = 7;
   
   reg [COUNTER_BITS-1:0] counter;
   
   always @(posedge clk)
     begin
        // 1. Hysteresis Counter Logic (Saturating)
        if (input_unstable == 1)
            counter <= (counter < {COUNTER_BITS{1'b1}}) ? counter + 1 : counter;
        else
            counter <= (counter > {COUNTER_BITS{1'b0}}) ? counter - 1 : counter;
            
        // 2. Pulse Generation Logic (The TODO part)
        // We fire a pulse when we are ABOUT to cross the threshold.
        // Threshold = 2^(COUNTER_BITS-1). For 7 bits, this is 64.
        // We trigger when counter is 63 AND input is 1 (Next state will be 64).
        
        if (input_unstable && (counter == (1 << (COUNTER_BITS-1)) - 1))
            output_stable <= 1;
        else
            output_stable <= 0;
            
     end
       
endmodule

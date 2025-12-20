`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
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
   reg state; // Internal state to track if we are currently "pressed" or "released"
   
   // Hysteresis counter logic
   always @(posedge clk) begin
        // 1. Counter Saturation Logic
        if (input_unstable == 1) begin
            // Increment unless maxed out (all 1s)
            if (counter < {COUNTER_BITS{1'b1}})
                counter <= counter + 1;
        end
        else begin
            // Decrement unless empty (all 0s)
            if (counter > {COUNTER_BITS{1'b0}})
                counter <= counter - 1;
        end
            
        // 2. Pulse Generation Logic 
        // We generate a pulse ONLY when we transition from "unpressed" to "pressed".
        
        // Reset the pulse by default every cycle
        output_stable <= 0;

        if (counter == {COUNTER_BITS{1'b1}}) begin
            // If counter is FULL...
            if (state == 0) begin
                output_stable <= 1; // Fire the pulse!
                state <= 1;         // Mark as "pressed" so we don't fire again
            end
        end
        else if (counter == {COUNTER_BITS{1'b0}}) begin
            // If counter is EMPTY...
            state <= 0;             // Mark as "released", ready for next press
        end
   end
       
endmodule
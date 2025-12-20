`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 08:59:38 PM
// Design Name:     EE3 lab1
// Module Name:     Ctl
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     Control module that receives reset, trig and split inputs.
//                  Outputs init_regs and count_enabled to govern the Counter.
// Dependencies:    None
//
// Revision:  	    3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Ctl(clk, reset, trig, split, init_regs, count_enabled);
   input clk, reset, trig, split;
   output init_regs, count_enabled;
   
   //-------------Internal Constants--------------------------
   localparam SIZE = 3;
   localparam IDLE  = 3'b001, COUNTING = 3'b010, PAUSED = 3'b100;
   reg [SIZE-1:0] state;

   //-------------Transition Function (Delta) ----------------
   // Implements the State Transitions from Figure 1 
   always @(posedge clk) begin
        if (reset) begin
            // Universal reset transition (1** -> IDLE) [cite: 228]
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    // If trig is pressed (01*), go to COUNTING. 
                    // Otherwise (00*), stay in IDLE. [cite: 228, 230]
                    if (trig)
                        state <= COUNTING;
                    else
                        state <= IDLE;
                end

                COUNTING: begin
                    // If trig is pressed (01*), go to PAUSED.
                    // Otherwise (00*), stay in COUNTING. [cite: 232, 238]
                    if (trig)
                        state <= PAUSED;
                    else
                        state <= COUNTING;
                end

                PAUSED: begin
                    // If trig is pressed (01*), resume to COUNTING. [cite: 233]
                    if (trig)
                        state <= COUNTING;
                    // If split is pressed (and trig is 0) (001), go to IDLE. [cite: 234, 241]
                    else if (split)
                        state <= IDLE;
                    // Otherwise (000), stay PAUSED. [cite: 236]
                    else
                        state <= PAUSED;
                end
                
                // Recovery for undefined states
                default: state <= IDLE;
            endcase
        end
   end
     
   //-------------Output Function (Lambda) ----------------
   

   assign init_regs = (state == IDLE);


   assign count_enabled = (state == COUNTING);

endmodule
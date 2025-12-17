`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Leo Segre
// 
// Create Date:     05/05/2019 00:19 AM
// Design Name:     EE3 lab1
// Module Name:     Stash
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     a Stash that stores all the samples in order upon sample_in and sample_in_valid.
//                  It exposes the chosen sample by sample_out and the exposed sample can be changed by next_sample. 
// Dependencies:    Lim_Inc
//
// Revision         1.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Stash(clk, reset, sample_in, sample_in_valid, next_sample, sample_out);
    parameter DEPTH = 5;
    // Calculate pointer width based on Depth
    localparam PTR_WIDTH = $clog2(DEPTH); 

    input clk, reset, sample_in_valid, next_sample;
    input [7:0] sample_in;
    output [7:0] sample_out;
  
    // --- Internal Registers ---
    reg [7:0] memory [DEPTH-1:0];      // The storage array
    reg [PTR_WIDTH-1:0] write_ptr;     // Points to next empty slot
    reg [PTR_WIDTH-1:0] read_ptr;      // Points to currently exposed slot
    integer i;                         // Iterator for reset loop

    // --- Wire definitions for Lim_Inc outputs ---
    wire [PTR_WIDTH-1:0] next_write_ptr_val;
    wire [PTR_WIDTH-1:0] next_read_ptr_val;
    wire wp_co, rp_co; // Unused carry-outs

    // --- 1. Write Pointer Logic (Circular Increment) ---
    // Increments 'write_ptr' by 1 if 'sample_in_valid' is high.
    // Wraps around DEPTH.
    Lim_Inc #(.L(DEPTH)) write_logic (
        .a(write_ptr),
        .ci(sample_in_valid),
        .sum(next_write_ptr_val),
        .co(wp_co)
    );

    // --- 2. Read Pointer Logic (Circular Increment) ---
    // Increments 'read_ptr' by 1 if 'next_sample' is high.
    // Wraps around DEPTH.
    Lim_Inc #(.L(DEPTH)) read_logic (
        .a(read_ptr),
        .ci(next_sample),
        .sum(next_read_ptr_val),
        .co(rp_co)
    );

    // --- 3. Synchronous Logic (State Updates) ---
    always @(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
            read_ptr  <= 0;
            // Clear all memory slots
            for (i = 0; i < DEPTH; i = i + 1) begin
                memory[i] <= 8'b0;
            end
        end
        else begin
            // --- Write Handling ---
            if (sample_in_valid) begin
                memory[write_ptr] <= sample_in; // Store new sample
                write_ptr <= next_write_ptr_val;// Advance write pointer
            end
            
            // --- Read/Next Handling ---
            else begin
                // Only advance read pointer if we are NOT writing a new sample.
                // (Writing takes priority for the view).
                read_ptr <= next_read_ptr_val;
            end
        end
    end

    // --- 4. Output Logic (The Bypass) ---
    // If we are currently sampling, show 'sample_in' directly.
    // Otherwise, show the value stored at 'read_ptr'.
    assign sample_out = (sample_in_valid) ? sample_in : memory[read_ptr];

endmodule
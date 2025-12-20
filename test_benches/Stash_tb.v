`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Yuval Horowitz and Ron Amrani
// 
// Create Date:     05/05/2019 02:59:38 AM
// Design Name:     EE3 lab1
// Module Name:     Stash_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     test bennch for the stash.
// Dependencies:    None
//
// Revision: 		1.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Stash_tb();

    reg clk, reset, sample_in_valid, next_sample, correct, loop_was_skipped;
    reg [7:0] sample_in;
    wire [7:0] sample_out;
    integer ini;
    
    // -----------------------------------------------------------
    // 1. INSTANTIATE THE UUT
    // -----------------------------------------------------------
    Stash #(.DEPTH(5)) uut (
        .clk(clk),
        .reset(reset),
        .sample_in(sample_in),
        .sample_in_valid(sample_in_valid),
        .next_sample(next_sample),
        .sample_out(sample_out)
    );
    
    initial begin
        correct = 1;
        clk = 0; 
        reset = 1; 
        loop_was_skipped = 1;
        
        // Initialize Inputs
        sample_in = 0;
        sample_in_valid = 0;
        next_sample = 0;

        #6;
        reset = 0;

        // -----------------------------------------------------------
        // 2. TEST LOOP (Write 7 samples to depth 5 buffer)
        // -----------------------------------------------------------
        // We write 0, 1, 2, 3, 4 (Full) -> then 5, 6 (Wrap around/Overwrite)
        for( ini=0; ini<7; ini=ini+1 ) begin
            
            // FILL HERE: Drive inputs
            sample_in = ini;       // Data is just the index
            sample_in_valid = 1;   // We are writing
            next_sample = 0;       // Not changing read pointer yet
            
            #10; // Wait for clock edge (clk period is 10ns)
            
            // FILL HERE: Verification
            // Test the "Bypass" logic: When sample_in_valid is 1, 
            // the output must show the input immediately.
            if (sample_out !== sample_in) begin
                correct = 0;
                $display("Error at time %t: Input=%d, Output=%d (Bypass Failed)", 
                         $time, sample_in, sample_out);
            end
            
            loop_was_skipped = 0;
        end
        
        #5;
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
    
    always #5 clk = ~clk;
    
endmodule

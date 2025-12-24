`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Leo Segre
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
module Stash_Read_tb_2();

    reg clk, reset, sample_in_valid, next_sample, correct, loop_was_skipped;
    reg [7:0] sample_in;
    wire [7:0] sample_out;
    integer ini;
    
    // -----------------------------------------------------------
    // 1. INSTANTIATE THE UUT
    // -----------------------------------------------------------
    Stash #(.DEPTH(5)) uut (
        //inputs
        .clk(clk),
        .reset(reset),
        .sample_in(sample_in),
        .sample_in_valid(sample_in_valid),
        .next_sample(next_sample),
        //outputs
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

        $display("Starting Write Loop: 7 samples into Depth 5...");
        // -----------------------------------------------------------
        // 2. TEST LOOP (Write 7 samples to depth 5 buffer)
        // -----------------------------------------------------------
        // We write 0, 1, 2, 3, 4 (Full) -> then 5, 6 (Wrap around/Overwrite)
        for( ini=0; ini<7; ini=ini+1 ) begin
            
            //Drive inputs
            sample_in = ini;       // Data is just the index
            sample_in_valid = 1;   // We are writing
            next_sample = 0;

            #1;

            if (sample_out !== sample_in) begin
                correct = 0;
                $display("Error at time %t: Input=%d, Output=%d (Bypass Failed)", $time, sample_in, sample_out);
            end
            #9; // Wait for rest of clock period
            sample_in_valid = 0;   //stop writing
            #10;

            #10; // Wait for clock edge (clk period is 10ns)
            
            // FILL HERE: Verification
            // Test the "Bypass" logic: When sample_in_valid is 1, 
            // the output must show the input immediately.
            
            loop_was_skipped = 0;
        end
        sample_in_valid = 0; // Stop writing
        #10;

        if (sample_out !== 5) begin 
            correct = 0;
            $display("Error at time %t: Stored data mismatch! Expected 5, Got %d", $time, sample_out);
        end

// 4. TEST READ LOGIC (Pulsing next_sample)
        $display("Cycling through memory...");
        for (ini = 0; ini < 5; ini = ini + 1) begin
            next_sample = 1;
            #10; // Pulse for one clock cycle
            next_sample = 0;
            #10;
            
            $display("At time %t, Read Pointer moved. Current sample_out: %d", $time, sample_out);
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

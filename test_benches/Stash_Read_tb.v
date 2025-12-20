`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:     Stash_Read_tb
// Description:     Verifies 'next_sample' and circular buffer reading.
//////////////////////////////////////////////////////////////////////////////////

module Stash_Read_tb();

    reg clk, reset, sample_in_valid, next_sample;
    reg [7:0] sample_in;
    wire [7:0] sample_out;
    
    reg correct;
    integer i;
    reg [7:0] expected_values [0:4]; // Array to store what we expect

    // 1. INSTANTIATE UUT
    Stash #(.DEPTH(5)) uut (
        .clk(clk),
        .reset(reset),
        .sample_in(sample_in),
        .sample_in_valid(sample_in_valid),
        .next_sample(next_sample),
        .sample_out(sample_out)
    );
    
    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        sample_in_valid = 0;
        next_sample = 0;
        correct = 1;
        
        // Define expected pattern
        expected_values[0] = 10;
        expected_values[1] = 20;
        expected_values[2] = 30;
        expected_values[3] = 40;
        expected_values[4] = 50;

        #25;
        reset = 0;

        // -------------------------------------------------------
        // PHASE 1: FILL THE STASH (Write 5 values)
        // -------------------------------------------------------
        $display("--- Phase 1: Filling Stash ---");
        for (i = 0; i < 5; i = i + 1) begin
            sample_in = expected_values[i];
            sample_in_valid = 1;
            #10; // Clock edge writes value
        end
        
        // Stop writing
        sample_in_valid = 0;
        sample_in = 8'hFF; // Garbage on input to prove we aren't bypassing
        #10; // Wait one cycle to settle

        // -------------------------------------------------------
        // PHASE 2: VERIFY READING (next_sample)
        // -------------------------------------------------------
        $display("--- Phase 2: Verifying Read Sequence ---");
        
        // We expect to see 10, 20, 30, 40, 50, then wrap to 10, 20...
        // We will cycle 7 times to prove wrap-around.
        for (i = 0; i < 7; i = i + 1) begin
            
            // 1. Check current output (Before clicking 'next')
            // The logic uses the modulo operator (%) to handle the expected index: 0,1,2,3,4,0,1
            if (sample_out !== expected_values[i % 5]) begin
                correct = 0;
                $display("Error at time %t: Index %d. Expected %d, Got %d", 
                         $time, i, expected_values[i % 5], sample_out);
            end else begin
                 $display("Time %t: Index %d. Correctly reading %d", $time, i, sample_out);
            end

            // 2. Pulse next_sample to advance pointer for NEXT cycle
            next_sample = 1;
            #10; // Wait for clock edge to process the increment
            next_sample = 0; // De-assert (though holding it 1 would just keep scrolling)
            
            // Small buffer to let logic settle (though synchronous update happens at edge)
             #1; 
        end

        #10;
        if (correct)
            $display("Test Passed - Read Logic Verified");
        else
            $display("Test Failed");
            
        $finish;
    end
endmodule
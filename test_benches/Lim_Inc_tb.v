`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 00:16 AM
// Design Name:     EE3 lab1
// Module Name:     Lim_Inc_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool Versions:   Vivado 2016.4
// Description:     Limited incrementor test bench
// 
// Dependencies:    Lim_Inc
// 
// Revision:        3.0
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Lim_Inc_tb();

    reg [3:0] a; 
    reg ci, correct, loop_was_skipped;
    wire [3:0] sum;
    wire co;
    
    integer ai,cii;
    
    // Variables for verifying results
    integer calc_val; 
    integer expected_sum, expected_co;

    // -----------------------------------------------------------
    // 1. INSTANTIATE THE UUT
    // -----------------------------------------------------------
    Lim_Inc #(.L(11)) uut (
        .a(a),      
        .ci(ci), 
        .sum(sum),
        .co(co)
    );
    
    initial begin
        correct = 1;
        loop_was_skipped = 1;
        #1;
        
        // -----------------------------------------------------------
        // 2. TEST LOOP
        // -----------------------------------------------------------
        // Testing all possible 3-bit values (0 to 7)
        for (ai = 0; ai < 16; ai = ai + 1) begin
            for (cii = 0; cii <= 1; cii = cii + 1) begin
                
                // Drive Inputs
                a = ai;
                ci = cii;

                #10; // Wait for logic to settle

                // -------------------------------------------------------
                // 3. VERIFICATION LOGIC
                // -------------------------------------------------------
                // Calculate arithmetic sum
                calc_val = ai + cii;
                // Apply Limited Incrementor Logic (L=7)
                // Rule: If (a + ci) >= L, then sum=0, co=1. Else pass simple sum.
                if (calc_val >= 11) begin
                    expected_sum = 0;
                    expected_co  = 1;
                end else begin
                    expected_sum = calc_val;
                    expected_co  = 0;
                end

                // Compare Outputs
                if (sum !== expected_sum || co !== expected_co) begin
                    correct = 0;
                    $display("Error at time %t: Input a=%d, ci=%d", $time, ai, cii);
                    $display("Expected sum=%d, co=%d. Got sum=%d, co=%d", expected_sum, expected_co, sum, co);
                end
                
                loop_was_skipped = 0;
            end
        end
        #5;
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
endmodule

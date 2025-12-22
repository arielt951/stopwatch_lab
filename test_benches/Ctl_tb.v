`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:            Ariel Turnowski & Ofek Goshen
// 
// Create Date:     05/05/2019 02:59:38 AM
// Design Name:     EE3 lab1
// Module Name:     Ctl_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     test bennch for the control.
// Dependencies:    None
//
// Revision: 		3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Ctl_tb();

    reg clk, reset, trig, split, correct, loop_was_skipped;
    wire init_regs, count_enabled;
    //integer ai,cii;
    
   Ctl uut (
    //inputs
        .clk(clk), 
        .reset(reset), 
        .trig(trig), 
        .split(split), 
        //outputs
        .init_regs(init_regs), 
        .count_enabled(count_enabled)
    );
    
    initial begin
        correct = 1;
        clk = 0; 
        reset = 1; 
        trig = 0;
        split = 0;
        
        // --- 1. TEST RESET -> IDLE ---
        #10;
        reset = 0; 
        
        // Expect: IDLE (init=1, en=0)
        if (init_regs !== 1 || count_enabled !== 0) begin
            correct = 0;
            $display("Error at %t: Expected IDLE. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end

        // --- 2. TEST IDLE -> COUNTING ---
        #10;
        trig = 1; 
        #10;
        trig = 0;
        
        // Expect: COUNTING (init=0, en=1)
        if (init_regs !== 0 || count_enabled !== 1) begin
            correct = 0;
            $display("Error at %t: Expected COUNTING. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end

        // --- 3. TEST COUNTING -> PAUSED ---
        #10;
        trig = 1;
        #10;
        trig = 0;
        
        // Expect: PAUSED (init=0, en=0)
        if (init_regs !== 0 || count_enabled !== 0) begin
            correct = 0;
            $display("Error at %t: Expected PAUSED. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end

        // --- 4. TEST PAUSED -> COUNTING (Resume) ---
        #10;
        trig = 1;
        #10;
        trig = 0;
        
        // Expect: COUNTING
        if (init_regs !== 0 || count_enabled !== 1) begin
            correct = 0;
            $display("Error at %t: Expected RESUME. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end

        // --- 5. TEST COUNTING -> IDLE (Direct Reset) [NEW CHECK] ---
        // This is the missing check: 1** transition from Counting
        #10;
        reset = 1; // Assert Global Reset while counting
        #10;
        reset = 0;
        
        // Expect: IDLE (init=1, en=0)
        if (init_regs !== 1 || count_enabled !== 0) begin
            correct = 0;
            $display("Error at %t: Expected RESET from Counting. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end

        // --- 6. TEST PAUSED -> IDLE (Via Split) ---
        // First get back to Paused
        #10; trig = 1; #10; trig = 0; // To Counting
        #10; trig = 1; #10; trig = 0; // To Paused
        
        // Now hit Split
        #10;
        split = 1;
        #10;
        split = 0;
        
        // Expect: IDLE
        if (init_regs !== 1 || count_enabled !== 0) begin
            correct = 0;
            $display("Error at %t: Expected SPLIT-RESET. Got init=%b, en=%b", $time, init_regs, count_enabled);
        end
          
        #10;
        if (correct)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
    
    always #5 clk = ~clk;
    
endmodule

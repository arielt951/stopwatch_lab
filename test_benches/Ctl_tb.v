`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
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
        .clk(clk), .reset(reset), .trig(trig), .split(split), 
        .init_regs(init_regs), .count_enabled(count_enabled)
    );
    
    initial begin
        correct = 1;
        clk = 0; 
        reset = 1; 
        trig = 0;
        split = 0;
        #10
        reset = 0; 
        correct = correct & init_regs & ~count_enabled;
        #20
        // --- START TEST SEQUENCE ---
        
        // 1. Check IDLE State defaults
        // Expected: init_regs=1, count_enabled=0
        if (init_regs !== 1 || count_enabled !== 0) correct = 0;

        // 2. Press TRIG -> Move to COUNTING
        trig = 1; 
        #10; // Wait 1 clock
        trig = 0;
        #10;
        // Expected: init_regs=0, count_enabled=1
        if (init_regs !== 0 || count_enabled !== 1) correct = 0;

        // 3. Press TRIG -> Move to PAUSED
        trig = 1;
        #10;
        trig = 0;
        #10;
        // Expected: init_regs=0, count_enabled=0
        if (init_regs !== 0 || count_enabled !== 0) correct = 0;

        // 4. Press SPLIT -> Move to IDLE
        split = 1;
        #10;
        split = 0;
        #10;
        // Expected: Back to IDLE (init_regs=1)
        if (init_regs !== 1) correct = 0;

        #10
        
          
        if (correct)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
    
    always #5 clk = ~clk;
    
endmodule

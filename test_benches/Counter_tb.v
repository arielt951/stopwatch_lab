`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Yuval Horowitz and Ron Amrani
// Create Date:     00:00:00  AM 05/05/2019 
// Design Name:     EE3 lab1
// Module Name:     Counter_tb
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     test bench for Counter module
// Dependencies:    Counter
//
// Revision:        3.0
// Revision:        3.1 - changed  9999999 to 99999999 for a proper, 1sec delay, 
//                        in the inner test loop.
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Module Name:     Counter_tb
// Description:     Test bench for Counter module
//////////////////////////////////////////////////////////////////////////////////

module Counter_tb();

    reg clk, init_regs, count_enabled, correct, loop_was_skipped;
    wire [7:0] time_reading;
    wire [3:0] tens_seconds_wire;
    wire [3:0] ones_seconds_wire;
    integer ts, os, sync;
    
    // 1. INSTANTIATE THE UUT with Default 100MHz Parameter
    // We use the default CLK_FREQ = 100,000,000 as defined in Counter.v
    Counter uut (
        .clk(clk), 
        .init_regs(init_regs), 
        .count_enabled(count_enabled), 
        .time_reading(time_reading)
    );
    
    assign tens_seconds_wire = time_reading[7:4];
    assign ones_seconds_wire = time_reading[3:0];
    
    initial begin 
        #1
        sync = 0;
        correct = 1;
        loop_was_skipped = 1;
        clk = 1;
        init_regs = 1;
        count_enabled = 0;
        
        #20
        init_regs = 0;
        count_enabled = 1; // Start Counting
        //1 bilion + 21 is the minimal time delay in the loop
        // ---------------------------------------------------------------------
        // 2. VERIFICATION LOOP
        // ---------------------------------------------------------------------
        // Check for 2 seconds: 00 -> 01
        for( ts=0; ts<2; ts=ts+1 ) begin 
            for( os=0; os<10; os=os+1 ) begin 
                
                // VERIFICATION
                // We check the value *before* waiting for the next second.
                // At os=0, we expect 0. At os=1, we expect 1.
                if (tens_seconds_wire !== ts || ones_seconds_wire !== os) begin
                     correct = 0;
                     $display("Error at time %t: Expected %d%d, Got %d%d", 
                              $time, ts, os, tens_seconds_wire, ones_seconds_wire);
                end

                // WAIT FOR 1 SECOND
                // 100 MHz clock = 10ns period.
                // 1 sec = 100,000,000 cycles * 10ns = 1,000,000,000 ns
                // We add 'sync' to slightly offset the check from the edge in the second pass.
                #(1000000000 + 100 + sync); 
                
                sync = sync | 1;
                loop_was_skipped = 0;
           end
        end
        
        #5
        if (correct && ~loop_was_skipped)
            $display("Test Passed - %m");
        else
            $display("Test Failed - %m");
        $finish;
    end
    
    // 100MHz Clock Generation (Period = 10ns)
    always #5 clk = ~clk;

endmodule
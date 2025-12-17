`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 00:19 AM
// Design Name:     EE3 lab1
// Module Name:     Counter
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     a counter that advances its reading as long as time_reading 
//                  signal is high and zeroes its reading upon init_regs=1 input.
//                  the time_reading output represents: 
//                  {dekaseconds,seconds}
// Dependencies:    Lim_Inc
//
// Revision         3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Counter(clk, init_regs, count_enabled, time_reading);
   parameter CLK_FREQ = 100000000; // in Hz
   
   input clk, init_regs, count_enabled;
   output [7:0] time_reading;
   
   // Registers to hold current state
   reg [$clog2(CLK_FREQ)-1:0] clk_cnt;
   reg [3:0] ones_seconds;    
   reg [3:0] tens_seconds;      
   
   // Wires to connect Lim_Inc outputs (Combinational next state)
   wire [$clog2(CLK_FREQ)-1:0] next_clk_cnt;
   wire [3:0] next_ones_seconds;
   wire [3:0] next_tens_seconds;
   
   // Carry wires (Overflow signals)
   wire co_1Hz;  // Ticks every 1 second
   wire co_10s;  // Ticks every 10 seconds
   wire co_100s; // Ticks every 100 seconds (unused output)

   // FILL HERE THE LIMITED-COUNTER INSTANCES
   
   // 1. Frequency Divider: Counts 0 to 99,999,999. 
   // 'ci' is count_enabled. When it wraps, co_1Hz goes high for 1 cycle.
   Lim_Inc #(.L(CLK_FREQ)) divider (
       .a(clk_cnt),
       .ci(count_enabled),
       .sum(next_clk_cnt),
       .co(co_1Hz)
   );

   // 2. Seconds Counter (Ones): Counts 0 to 9.
   // 'ci' is the carry-out from the divider.
   Lim_Inc #(.L(10)) seconds_ones (
       .a(ones_seconds),
       .ci(co_1Hz),
       .sum(next_ones_seconds),
       .co(co_10s)
   );

   // 3. Seconds Counter (Tens): Counts 0 to 9.
   // 'ci' is the carry-out from the ones counter.
   Lim_Inc #(.L(10)) seconds_tens (
       .a(tens_seconds),
       .ci(co_10s),
       .sum(next_tens_seconds),
       .co(co_100s)
   );
   
   //------------- Synchronous ----------------
   always @(posedge clk)
     begin
        // FILL HERE THE ADVANCING OF THE REGISTERS AS A FUNCTION OF init_regs, count_enabled
        if (init_regs) begin
            // Synchronous Reset
            clk_cnt      <= 0;
            ones_seconds <= 0;
            tens_seconds <= 0;
        end
        else begin
            // Update registers with the "next" values calculated by Lim_Inc
            // Lim_Inc handles the increment logic internally.
            // If count_enabled is 0, Lim_Inc returns sum = a, so state holds.
            clk_cnt      <= next_clk_cnt;
            ones_seconds <= next_ones_seconds;
            tens_seconds <= next_tens_seconds;
        end
     end
     
   // Concatenate nibbles for output: {Tens, Ones}
   assign time_reading = {tens_seconds, ones_seconds};

endmodule

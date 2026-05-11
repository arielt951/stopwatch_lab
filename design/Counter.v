`timescale 1ns/10ps
////
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     11/12/2018 08:59:38 PM
// Design Name:     EE3 lab1
// Module Name:     Counter
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     A counter that advances its reading as long as time_reading 
//                  signal is high and zeroes its reading upon init_regs=1 input.
//                  the time_reading output represents: 
//                  {dekaseconds,seconds:deciseconds,centiseconds}
// Dependencies:    Lim_Inc
//
// Revision:        2.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Counter(clk, init_regs, count_enabled, count_sample, show_sample, time_reading);

   parameter CLK_FREQ = 100000000;// in Hz
   
   input clk, init_regs, count_enabled, count_sample, show_sample;
   output [15:0] time_reading;
   
  // Registers to hold current state
   reg [$clog2(CLK_FREQ/100)-1:0] clk_cnt;
   reg [3:0] centi_seconds;
   reg [3:0] deci_seconds;
   reg [3:0] ones_seconds;    
   reg [3:0] tens_seconds; 

  //register to hold the current full time
   reg[15:0] sampeled_time;

  // Wires to connect Lim_Inc outputs (Combinational next state)
   wire [$clog2(CLK_FREQ/100)-1:0] next_clk_cnt;
   wire [3:0] next_centi_seconds;
   wire [3:0] next_deci_seconds;
   wire [3:0] next_seconds;
   wire [3:0] next_da_seconds;
   wire [15:0] time_reading_pre;
  

  // Carry wires (Overflow signals)
   wire co_100Hz;  // Ticks every 0.01 second
   wire co_10Hz;  // Ticks every 0.1 second
   wire co_1Hz;  // Ticks every 1 second
   wire co_0_1Hz;  // Ticks every 10 seconds
   wire co_0_01Hz; // Ticks every 100 seconds (unused output)     
   
  // FILL HERE THE LIMITED-COUNTER INSTANCES
   Lim_Inc #(.L(CLK_FREQ/100)) divider (
       .a(clk_cnt),
       .ci(count_enabled),
       .sum(next_clk_cnt),
       .co(co_100Hz)
   );
   Lim_Inc #(.L(10)) CSEC (
       .a(centi_seconds),
       .ci(co_100Hz),
       .sum(next_centi_seconds),
       .co(co_10Hz)
   );
   Lim_Inc #(.L(10)) DSEC (
       .a(deci_seconds),
       .ci(co_10Hz),
       .sum(next_deci_seconds),
       .co(co_1Hz)
   );
   Lim_Inc #(.L(10)) SEC (
       .a(ones_seconds),
       .ci(co_1Hz),
       .sum(next_seconds),
       .co(co_0_1Hz)
   ); 
   Lim_Inc #(.L(10)) DASEC (
       .a(tens_seconds),
       .ci(co_0_1Hz),
       .sum(next_da_seconds),
       .co(co_0_01Hz)
   );   
    
  assign time_reading_pre={tens_seconds,ones_seconds,deci_seconds,centi_seconds};
  assign time_reading=show_sample?sampeled_time:time_reading_pre;
   
   //------------- Synchronous ----------------
   always @(posedge clk)
     begin
		// FILL HERE THE ADVANCING OF THE REGISTERS AS A FUNCTION OF init_regs, count_enabled
        if (init_regs) begin
            // Synchronous Reset
            clk_cnt      <= 0;
            centi_seconds <= 0;
            deci_seconds <= 0;
            ones_seconds<= 0;
            tens_seconds<= 0;
            sampeled_time<= 0;

        end
        else begin
            // Update registers with the "next" values calculated by Lim_Inc
            // Lim_Inc handles the increment logic internally.
            // If count_enabled is 0, Lim_Inc returns sum = a, so state holds.
            clk_cnt      <= next_clk_cnt;
            centi_seconds<=next_centi_seconds;
            deci_seconds<=next_deci_seconds;
            ones_seconds <= next_seconds;
            tens_seconds <= next_da_seconds;
            if (count_sample)begin
          sampeled_time<=time_reading_pre;
          end
          else begin
            sampeled_time<=sampeled_time;
          end
        end
        
     end
   
endmodule

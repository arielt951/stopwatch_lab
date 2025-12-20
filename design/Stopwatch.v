`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        
// 
// Create Date:     05/05/2019 01:28AM
// Design Name:     EE3 lab1
// Module Name:     Stopwatch
// Project Name:    Electrical Lab 3, FPGA Experiment #1
// Target Devices:  Xilinx BASYS3 Board, FPGA model XC7A35T-lcpg236C
// Tool versions:   Vivado 2016.4
// Description:     Top module of the stopwatch circuit. Displays 2 independent 
//                  stopwatches on the 4 digits of the 7-segment component.
//                  Uses btnC as reset, btnU as trigger, and btnR as split button to
//                  control the currently selected stopwatch.
//                  Pressing btnL at any time - toggles the selection between the 
//                  left hand side (LHS) and the RHS stopwatches.
//                  The stopwatch's time reading is outputted using an, seg and dp signals
//                  that should be connected to the 4-digit-7-segment display and driven
//                  by 100MHz clock. 
// Dependencies:    Debouncer, Ctl, Counter, Seg_7_Display
//
// Revision:        3.0
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Stopwatch(clk, btnC, btnU, btnR, btnL, seg, an, dp, led_left, led_right);

    input              clk, btnC, btnU, btnR, btnL;
    output  wire [6:0] seg;
    output  wire [3:0] an;
    output  wire       dp; 
    output  wire [2:0] led_left;
    output  wire [2:0] led_right;

    wire [15:0] time_reading;
    wire trig, split, reset, toggle;
    wire trig_right, split_right, init_regs_right, count_enabled_right;
    wire trig_left, split_left, init_regs_left, count_enabled_left;
    reg selected_stopwatch;
    
// -------------------------------------------------------------------------
    // 1. INSTANTIATE DEBOUNCERS
    // -------------------------------------------------------------------------
    Debouncer db_reset  (.clk(clk),
                         .input_unstable(btnC),
                         .output_stable(reset));

    Debouncer db_trig   (.clk(clk),
                         .input_unstable(btnU),
                         .output_stable(trig));

    Debouncer db_split  (.clk(clk),
                         .input_unstable(btnR),
                         .output_stable(split));

    Debouncer db_toggle (.clk(clk),
                         .input_unstable(btnL),
                         .output_stable(toggle));

    // -------------------------------------------------------------------------
    // 2. SELECTION LOGIC
    // -------------------------------------------------------------------------
    // Toggle the active stopwatch when btnL is pressed
    always @(posedge clk) begin
        if (reset)
            selected_stopwatch <= 0; // Default to Right
        else if (toggle)
            selected_stopwatch <= ~selected_stopwatch;
    end

    // Visual Feedback: Light up LEDs to show which side is active
    assign led_right = (selected_stopwatch == 0) ? 3'b111 : 3'b000;
    assign led_left  = (selected_stopwatch == 1) ? 3'b111 : 3'b000;

    // -------------------------------------------------------------------------
    // 3. SIGNAL ROUTING (DEMUX)
    // -------------------------------------------------------------------------
    // If Right is selected (0), route signals there. Otherwise send 0.
    assign trig_right  = (selected_stopwatch == 0) ? trig : 1'b0;
    assign split_right = (selected_stopwatch == 0) ? split : 1'b0;

    // If Left is selected (1), route signals there. Otherwise send 0.
    assign trig_left   = (selected_stopwatch == 1) ? trig : 1'b0;
    assign split_left  = (selected_stopwatch == 1) ? split : 1'b0;

    // -------------------------------------------------------------------------
    // 4. RIGHT STOPWATCH INSTANCES
    // -------------------------------------------------------------------------
    Ctl ctl_right (
        //inputs
        .clk            (clk),
        .reset          (reset),
        .trig           (trig_right),
        .split          (split_right),
        //outputs
        .init_regs      (init_regs_right),
        .count_enabled  (count_enabled_right)
    );

    Counter cnt_right (
    //inputs
        .clk            (clk),
        .init_regs      (init_regs_right),
        .count_enabled  (count_enabled_right),
        //outputs
        .time_reading   (time_right)
    );

    // -------------------------------------------------------------------------
    // 5. LEFT STOPWATCH INSTANCES
    // -------------------------------------------------------------------------
    Ctl ctl_left (
        //inputs
        .clk            (clk),
        .reset          (reset),
        .trig           (trig_left),
        .split          (split_left),
        //outputs
        .init_regs      (init_regs_left),
        .count_enabled  (count_enabled_left)
    );

    Counter cnt_left (
        .clk            (clk),
        .init_regs      (init_regs_left),
        .count_enabled  (count_enabled_left),
        //outputs
        .time_reading   (time_left)
    );

    // -------------------------------------------------------------------------
    // 6. DISPLAY DRIVER
    // -------------------------------------------------------------------------
    // Combine left and right times into one 16-bit vector: {Left, Right}
    assign time_reading = {time_left, time_right};

    Seg_7_Display display (
        .x              (time_reading),
        .clk            (clk),
        .clr            (reset),
        .a_to_g         (seg),
        .an             (an),
        .dp             (dp)
    );
endmodule

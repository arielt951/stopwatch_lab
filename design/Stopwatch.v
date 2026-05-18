`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Ariel Turnowski Ofek Goshen
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
// Module Name:     Stopwatch
// Description:     Top module implementing Stopwatch (Left) and Stash (Right).
//                  Follows PDF Task 9 specifications.
//////////////////////////////////////////////////////////////////////////////////

module Stopwatch(clk, btnC, btnU, btnR, btnL, seg, an, dp, led_left, led_right);
    input              clk, btnC, btnU, btnR, btnL;
    output  wire [6:0] seg;
    output  wire [3:0] an;
    output  wire       dp;
    output  wire [2:0] led_left;
    output  wire [2:0] led_right;

    // --- Internal Wires ---
    wire reset, trig, split, toggle;
    wire [15:0] display_data;
    
    // Left Stopwatch Wires
    wire [7:0] time_left;
    wire init_regs_left, count_enabled_left;
    wire ctl_trig_left, ctl_split_left;
    wire [7:0] view_left;
    
    // Right Stopwatch Wires
    wire [7:0] time_right;
    wire init_regs_right, count_enabled_right;
    wire ctl_trig_right, ctl_split_right;
    wire [7:0] view_right;
    
    reg selected_mode;          // 1 = Left, 0 = Right

    reg [7:0] split_time_left;
    reg split_mode_left;
    
    reg [7:0] split_time_right;
    reg split_mode_right;

    // -------------------------------------------------------------------------
    // 1. DEBOUNCERS
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
    // 2. MODE SELECTION AND SPLIT LOGIC
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin 
            split_time_left <= 8'b0;
            split_mode_left <= 0;
            split_time_right <= 8'b0;
            split_mode_right <= 0;
            selected_mode <= 1; // Default to Left
        end
        else begin 
            // Toggle selection
            if (toggle)
                selected_mode <= ~selected_mode;

            // Split Functionality - Left Stopwatch
            if (count_enabled_left && ctl_split_left) begin
                split_time_left <= time_left;
                split_mode_left <= 1;
            end
            else if (!count_enabled_left) begin
                split_mode_left <= 0;
            end
            
            // Split Functionality - Right Stopwatch
            if (count_enabled_right && ctl_split_right) begin
                split_time_right <= time_right;
                split_mode_right <= 1;
            end
            else if (!count_enabled_right) begin
                split_mode_right <= 0;
            end
        end
    end
    
    // LED Feedback: Show which side is currently controlled
    assign led_left  = (selected_mode == 1) ? 3'b111 : 3'b000;
    assign led_right = (selected_mode == 0) ? 3'b111 : 3'b000;

    // -------------------------------------------------------------------------
    // 3. SIGNAL ROUTING (Multiplexing Inputs)
    // -------------------------------------------------------------------------
    assign ctl_trig_left   = (selected_mode == 1) ? trig : 1'b0;
    assign ctl_split_left  = (selected_mode == 1) ? split : 1'b0;

    assign ctl_trig_right  = (selected_mode == 0) ? trig : 1'b0;
    assign ctl_split_right = (selected_mode == 0) ? split : 1'b0;

    // -------------------------------------------------------------------------
    // 4. STOPWATCH LOGIC (Left Side)
    // -------------------------------------------------------------------------
    Ctl control_unit_left (
        .clk(clk), 
        .reset(reset), 
        .trig(ctl_trig_left), 
        .split(ctl_split_left),
        .init_regs(init_regs_left), 
        .count_enabled(count_enabled_left)
    );

    Counter #(.CLK_FREQ(100000000)) timer_left (
        .clk(clk), 
        .init_regs(init_regs_left), 
        .count_enabled(count_enabled_left), 
        .time_reading(time_left)
    );

    // -------------------------------------------------------------------------
    // 5. STOPWATCH LOGIC (Right Side)
    // -------------------------------------------------------------------------
    Ctl control_unit_right (
        .clk(clk), 
        .reset(reset), 
        .trig(ctl_trig_right), 
        .split(ctl_split_right),
        .init_regs(init_regs_right), 
        .count_enabled(count_enabled_right)
    );

    Counter #(.CLK_FREQ(100000000)) timer_right (
        .clk(clk), 
        .init_regs(init_regs_right), 
        .count_enabled(count_enabled_right), 
        .time_reading(time_right)
    );

    // -------------------------------------------------------------------------
    // 6. DISPLAY DRIVER
    // -------------------------------------------------------------------------
    assign view_left = (split_mode_left) ? split_time_left : time_left;
    assign view_right = (split_mode_right) ? split_time_right : time_right;
    
    // Concatenate: [Left Digits: Stopwatch Left] [Right Digits: Stopwatch Right]
    assign display_data = {view_left, view_right};

    Seg_7_Display driver (
        .clk(clk),
        .clr(reset),
        .x(display_data),
        .a_to_g(seg),
        .an(an),
        .dp(dp)
    );

endmodule
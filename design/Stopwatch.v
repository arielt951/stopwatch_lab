`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Engineer:        Yuval Horowitz and Ron Amrani
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
module Stopwatch(clk, btnC, btnU, btnR, btnL, btnD, seg, an, dp, led_left, led_right);
    // Added btnD per Lab Manual specification for "Sample" button
    input              clk, btnC, btnU, btnR, btnL, btnD;
    output  wire [6:0] seg;
    output  wire [3:0] an;
    output  wire       dp;
    output  wire [2:0] led_left;
    output  wire [2:0] led_right;

    // The 16-bit bus displayed on the 7-Seg (Upper byte=Stopwatch, Lower byte=Stash)
    wire [15:0] time_reading;
    
    // Debounced button signals
    wire trig, split, reset, toggle, sample; 
    
    // Internal Control Signals
    // "Left" = Stopwatch logic, "Right" = Stash logic
    wire trig_right, split_right, init_regs_right, count_enabled_right; // 'Right' vars mostly unused/placeholders if Stash has no complex FSM
    wire trig_left, split_left, init_regs_left, count_enabled_left;
    
    // Stash/Stopwatch outputs
    wire [7:0] stopwatch_out;
    wire [7:0] stash_out;

    // Toggle State: 0 = Stopwatch Selected, 1 = Stash Selected
    reg selected_stopwatch; 
    
    // =========================================================================
    // 1. DEBOUNCERS
    // =========================================================================
    // We use the default parameter (COUNTER_BITS=7) for all buttons.
    Debouncer db_rst   (.clk(clk), .input_unstable(btnC), .output_stable(reset));  // Center = Reset
    Debouncer db_trig  (.clk(clk), .input_unstable(btnU), .output_stable(trig));   // Up = Trig / Next
    Debouncer db_split (.clk(clk), .input_unstable(btnR), .output_stable(split));  // Right = Split
    Debouncer db_tog   (.clk(clk), .input_unstable(btnL), .output_stable(toggle)); // Left = Toggle View
    Debouncer db_samp  (.clk(clk), .input_unstable(btnD), .output_stable(sample)); // Down = Sample to Stash

    // =========================================================================
    // 2. SELECTION LOGIC (Toggle Switch)
    // =========================================================================
    // Toggle the selection state whenever btnL (toggle) is pressed.
    // Reset sets it back to Stopwatch view.
    always @(posedge clk) begin
        if (reset)
            selected_stopwatch <= 0;
        else if (toggle)
            selected_stopwatch <= ~selected_stopwatch;
    end
    
    // LEDs indicate selection:
    // Left LEDs ON (111) if selected_stopwatch == 0.
    // Right LEDs ON (111) if selected_stopwatch == 1.
    assign led_left  = (selected_stopwatch == 0) ? 3'b111 : 3'b000;
    assign led_right = (selected_stopwatch == 1) ? 3'b111 : 3'b000;

    // =========================================================================
    // 3. SIGNAL ROUTING
    // =========================================================================
    // The "trig" button (btnU) functionality depends on which view is selected.
    
    // STOPWATCH CONTROL (Left): Receives Trigger only if selected_stopwatch is 0.
    assign trig_left  = (selected_stopwatch == 0) ? trig : 1'b0;
    assign split_left = split; // Split button is dedicated to Stopwatch (per manual)

    // STASH CONTROL (Right): Receives "Next Sample" (trig) only if selected_stopwatch is 1.
    assign trig_right = (selected_stopwatch == 1) ? trig : 1'b0;

    // =========================================================================
    // 4. MODULE INSTANTIATIONS
    // =========================================================================

    // --- Control FSM (Stopwatch Controller) ---
    Ctl main_ctl (
        .clk(clk),
        .reset(reset),
        .trig(trig_left),
        .split(split_left),
        .init_regs(init_regs_left),
        .count_enabled(count_enabled_left)
    );

    // --- Counter (The Stopwatch Engine) ---
    // Note: We use 100MHz parameter.
    Counter #(.CLK_FREQ(100000000)) main_counter (
        .clk(clk),
        .init_regs(init_regs_left),
        .count_enabled(count_enabled_left),
        .time_reading(stopwatch_out) // 8-bit output
    );

    // --- Stash (The Memory) ---
    Stash #(.DEPTH(5)) main_stash (
        .clk(clk),
        .reset(reset),
        .sample_in(stopwatch_out),   // Input is always the current Stopwatch time
        .sample_in_valid(sample),    // Valid only when btnD is pressed
        .next_sample(trig_right),    // Advances read pointer (if Stash is selected)
        .sample_out(stash_out)       // 8-bit output
    );

    // --- Display Driver ---
    // Concatenate stopwatch (High Byte) and Stash (Low Byte) for the display input.
    // Structure: [Stopwatch_Tens][Stopwatch_Ones][Stash_Tens][Stash_Ones]
    assign time_reading = {stopwatch_out, stash_out};
    
    Seg_7_Display display_driver (
        .clk(clk),
        .clr(reset),
        .x(time_reading),
        .a_to_g(seg),
        .an(an),
        .dp(dp)
    );

endmodule

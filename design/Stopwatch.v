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
`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:     Stopwatch
// Description:     Top module implementing Stopwatch (Left) and Stash (Right).
//                  Follows PDF Task 9 specifications.
//////////////////////////////////////////////////////////////////////////////////

module Stopwatch(clk, btnC, btnU, btnR, btnL, btnD, seg, an, dp, led_left, led_right);
    input              clk, btnC, btnU, btnR, btnL, btnD;
    output  wire [6:0] seg;
    output  wire [3:0] an;
    output  wire       dp;
    output  wire [2:0] led_left;
    output  wire [2:0] led_right;

    // --- Internal Wires ---
    wire reset, trig, split, toggle, sample_btn;
    wire [15:0] display_data;
    wire [7:0] current_time;    // Output from Counter
    wire [7:0] stash_output;    // Output from Stash
    
    // Control Signals
    wire init_regs, count_enabled;
    wire ctl_trig, ctl_split;   // Signals routed to Ctl
    wire stash_next;            // Signal routed to Stash
    
    reg selected_mode;          // 0 = Stash (Right), 1 = Stopwatch (Left)

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

    Debouncer db_sample (.clk(clk),
                         .input_unstable(btnD),
                         .output_stable(sample_btn));

    // -------------------------------------------------------------------------
    // 2. MODE SELECTION (btnL)
    // -------------------------------------------------------------------------
    // Toggle between controlling Stopwatch (1) and Stash (0)
    always @(posedge clk) begin
        if (reset)
            selected_mode <= 1; // Default to Stopwatch
        else if (toggle)
            selected_mode <= ~selected_mode;
    end

    // LED Feedback: Show which side is currently controlled
    assign led_left  = (selected_mode == 1) ? 3'b111 : 3'b000;
    assign led_right = (selected_mode == 0) ? 3'b111 : 3'b000;

    // -------------------------------------------------------------------------
    // 3. SIGNAL ROUTING (Multiplexing Inputs)
    // -------------------------------------------------------------------------
    // btnU (Trigger/Next):
    //   - If Mode=Stopwatch (1): Goes to Ctl.trig
    //   - If Mode=Stash (0):     Goes to Stash.next_sample
    assign ctl_trig   = (selected_mode == 1) ? trig : 1'b0;
    assign stash_next = (selected_mode == 0) ? trig : 1'b0;

    // btnR (Split/Reset):
    //   - Only used by Stopwatch (Ctl). Stash ignores it.
    assign ctl_split  = (selected_mode == 1) ? split : 1'b0;

    // -------------------------------------------------------------------------
    // 4. STOPWATCH LOGIC (Left Side)
    // -------------------------------------------------------------------------
    Ctl control_unit (
        //inputs
        .clk(clk), 
        .reset(reset), 
        .trig(ctl_trig), 
        .split(ctl_split),
        //outputs 
        .init_regs(init_regs), 
        .count_enabled(count_enabled)
    );

    Counter #(.CLK_FREQ(100000000)) timer (
        //inputs
        .clk(clk), 
        .init_regs(init_regs), 
        .count_enabled(count_enabled), 
        //outputs
        .time_reading(current_time)
    );

    // -------------------------------------------------------------------------
    // 5. STASH LOGIC (Right Side)
    // -------------------------------------------------------------------------
    // Note: 'sample_btn' (btnD) works regardless of 'selected_mode' [cite: 522]
    Stash #(.DEPTH(5)) memory_unit (
        //inputs
        .clk(clk), 
        .reset(reset), 
        .sample_in(current_time), 
        .sample_in_valid(sample_btn), 
        .next_sample(stash_next), 
        //outputs
        .sample_out(stash_output)
    );

    // -------------------------------------------------------------------------
    // 6. DISPLAY DRIVER
    // -------------------------------------------------------------------------
    // Concatenate: [Left Digits: Stopwatch] [Right Digits: Stash]
    assign display_data = {current_time, stash_output};

    Seg_7_Display driver (
        //intputs
        .clk(clk),
        .clr(reset),
        .x(display_data),
        //outputs
        .a_to_g(seg),
        .an(an),
        .dp(dp)
    );

endmodule
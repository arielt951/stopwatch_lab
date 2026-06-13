`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Tel Aviv University
// Engineer: Ariel Turnowski & Ofek Goshen
// 
// Module Name: Ps2_Interface_tb
// Description: Smart Self-Checking Testbench covering Numpad + Backspace + Tab
//////////////////////////////////////////////////////////////////////////////////
module Ps2_Interface_tb;

    reg clk;
    reg rstn;
    reg PS2Clk;
    reg PS2Data;
    wire [7:0] scancode;
    wire keyPressed;

    integer errors; // Counter for test failures
    integer k;      // Loop variable
    localparam integer KEY_COUNT = 17;
    
    // Array to hold all keys (14 numpad + 3 special = 17 keys)
    reg [7:0] test_keys [0:16];
    reg [7:0] current_key;

    // Instantiate the UUT (Unit Under Test)
    Ps2_Interface uut (
        .PS2Clk(PS2Clk),
        .rstn(rstn),
        .PS2Data(PS2Data),
        .scancode(scancode),
        .keyPressed(keyPressed)
    );

    // =========================================================================
    // DEBUG WIRES FOR THE WAVEFORM (WAVES)
    // =========================================================================
    wire wave_start_bit  = uut.shift_reg[12];
    wire wave_parity_bit = uut.shift_reg[21];
    wire wave_stop_bit   = PS2Data;
    // Added explicit parentheses around the reduction XOR to be parser-safe
    wire wave_packet_valid = (PS2Data == 1'b1) && (uut.shift_reg[12] == 1'b0) && ((^uut.shift_reg[21:13]) == 1'b1);
    // =========================================================================

    // Clock generator (system clk for visualization)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // PS2 clock emulation task (Valid Odd Parity)
    task send_ps2_byte(input [7:0] data);
        integer i;
        reg parity;
        begin
            parity = ~^data; // Odd parity calculation
            PS2Data = 0; toggle_clk(); // Start bit
            for (i = 0; i < 8; i = i + 1) begin
                PS2Data = data[i]; toggle_clk();
            end
            PS2Data = parity; toggle_clk(); // Parity bit
            PS2Data = 1; toggle_clk(); // Stop bit
        end
    endtask

    // PS2 clock emulation task (INVALID Even Parity for error testing)
    task send_bad_parity_byte(input [7:0] data);
        integer i;
        reg parity;
        begin
            parity = ^data; // EVEN parity (Intentional Error)
            PS2Data = 0; toggle_clk(); 
            for (i = 0; i < 8; i = i + 1) begin
                PS2Data = data[i]; toggle_clk();
            end
            PS2Data = parity; toggle_clk(); 
            PS2Data = 1; toggle_clk(); 
        end
    endtask

    task toggle_clk;
        begin
            #50 PS2Clk = 0; 
            #50 PS2Clk = 1; 
        end
    endtask

    // Simulation Flow
    initial begin
        // Initialize Scan Codes (Standard PS/2 Set 2)
        test_keys[0]  = 8'h70; // 0
        test_keys[1]  = 8'h69; // 1
        test_keys[2]  = 8'h72; // 2
        test_keys[3]  = 8'h7A; // 3
        test_keys[4]  = 8'h6B; // 4
        test_keys[5]  = 8'h73; // 5
        test_keys[6]  = 8'h74; // 6
        test_keys[7]  = 8'h6C; // 7
        test_keys[8]  = 8'h75; // 8
        test_keys[9]  = 8'h7D; // 9
        test_keys[10] = 8'h71; // . (Dot)
        test_keys[11] = 8'h7C; // * (Multiply)
        test_keys[12] = 8'h7B; // - (Minus)
        test_keys[13] = 8'h79; // + (Plus)
        
        // New additions requested:
        test_keys[14] = 8'h66; // Backspace
        test_keys[15] = 8'h0D; // Tab
        test_keys[16] = 8'h5A; // ENTER

        // 1. Init signals
        errors = 0;
        PS2Clk = 1; 
        PS2Data = 1; 
        rstn = 0;
        #100;
        rstn = 1;
        #100;

        // -----------------------------------------------------------
        // SMART LOOP: Test ALL 17 Keys (Make and Break)
        // -----------------------------------------------------------
        $display("==================================================");
        $display("   STARTING KEY ITERATION TEST (17 KEYS)");
        $display("==================================================");
        
        for (k = 0; k < KEY_COUNT; k = k + 1) begin
            current_key = test_keys[k];
            $display("Testing Key [%0d/%0d] - Scan Code: 0x%h", k + 1, KEY_COUNT, current_key);
            
            // A. Send Make Code
            send_ps2_byte(current_key);
            #10;
            if (keyPressed !== 1'b1 || scancode !== current_key) begin
                $display("   -> ERROR on MAKE: Expected pulse on %h, got keyPressed=%b, scancode=%h", current_key, keyPressed, scancode);
                errors = errors + 1;
            end
            #200;

            // B. Send Break Code (0xF0 followed by the key)
            send_ps2_byte(8'hF0);
            #100;
            send_ps2_byte(current_key);
            #10;
            if (keyPressed !== 1'b0) begin
                $display("   -> ERROR on BREAK: Expected NO pulse on release of %h, got %b", current_key, keyPressed);
                errors = errors + 1;
            end
            #500;
        end
        $display("-> Iteration complete.\n");

        // -----------------------------------------------------------
        // EDGE CASES
        // -----------------------------------------------------------
        $display("==================================================");
        $display("   STARTING EDGE CASES");
        $display("==================================================");

        $display("1. Retransmission (Holding Numpad '5')");
        send_ps2_byte(8'h73); // Initial Press
        #500;
        send_ps2_byte(8'h73); // Held down
        #10;
        if (keyPressed !== 1'b0) begin
            $display("   -> ERROR: Expected NO pulse on retransmission, got %b", keyPressed);
            errors = errors + 1;
        end
        send_ps2_byte(8'hF0); send_ps2_byte(8'h73); // Release
        #500;

        $display("2. Parity Error Detection");
        send_bad_parity_byte(8'h7C);
        #10;
        if (keyPressed !== 1'b0) begin
            $display("   -> ERROR: Expected NO pulse on bad parity, got %b", keyPressed);
            errors = errors + 1;
        end
        #500;

        $display("3. Extended Break Sequence (0xE0 -> 0xF0 -> 0x75)");
        send_ps2_byte(8'hE0); 
        #100;
        send_ps2_byte(8'hF0); 
        #100;
        send_ps2_byte(8'h75); 
        #10;
        if (keyPressed !== 1'b0) begin
            $display("   -> ERROR: Expected NO pulse on extended break, got %b", keyPressed);
            errors = errors + 1;
        end
        #500;

        $display("4. Mid-Frame Reset Simulation");
        PS2Data = 0; toggle_clk(); // Start
        PS2Data = 1; toggle_clk(); // Bit 0
        PS2Data = 1; toggle_clk(); // Bit 1
        #50;
        rstn = 0; // Async reset triggers mid-frame
        #50;
        rstn = 1;
        #200;
        send_ps2_byte(8'h1C); // Fresh valid packet
        #10;
        if (keyPressed !== 1'b1 || scancode !== 8'h1C) begin
            $display("   -> ERROR: Module did not recover after reset!");
            errors = errors + 1;
        end
        #500;

        // Final Verdict
        $display("\n==================================================");
        if (errors == 0) begin
            $display("   TEST PASSED! All 17 keys and edge cases met.");
        end else begin
            $display("   TEST FAILED with %0d errors.", errors);
        end
        $display("==================================================\n");

        $finish;
    end

endmodule

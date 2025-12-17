`timescale 1ns/10ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         Tel Aviv University
// Module Name:     CSA
// Description:     Recursive Conditional Sum Adder
//////////////////////////////////////////////////////////////////////////////////

module CSA(a, b, ci, sum, co);
    parameter N = 4;
    // Calculate split point (Halfway)
    parameter K = N >> 1; 
    
    input [N-1:0] a;
    input [N-1:0] b;
    input ci;gjhjrtbnmiy
    output [N-1:0] sum;1e
    output co;
    
    generate
        // BASE CASE: If N=1, we just use a single Full Adder (FA)
        // This corresponds to the leaf nodes of your recursion tree.
        if (N == 1) begin : base_case
            FA fa_unit (
                .a(a[0]), 
                .b(b[0]), 
                .ci(ci), 
                .sum(sum[0]), 
                .co(co)
            );
        end
        
        // RECURSIVE STEP: If N > 1, we split into Lower and Upper halves
        else begin : recursive_step
            // Wires to capture results from sub-modules
            wire [K-1:0] sum_lower;
            wire         co_lower;
            
            // Note: N-K accounts for odd N (e.g., if N=5, K=2, Upper=3)
            wire [N-K-1:0] sum_upper_0, sum_upper_1;
            wire           co_upper_0,  co_upper_1;

            // 1. Lower Half: Calculate actual result (bits 0 to K-1)
            CSA #(.N(K)) lower_half (
                .a(a[K-1:0]),
                .b(b[K-1:0]),
                .ci(ci),
                .sum(sum_lower),
                .co(co_lower)
            );

            // 2. Upper Half (Option 0): Calculate assuming Carry-In = 0
            CSA #(.N(N-K)) upper_half_assume_0 (
                .a(a[N-1:K]),
                .b(b[N-1:K]),
                .ci(1'b0),
                .sum(sum_upper_0),
                .co(co_upper_0)
            );

            // 3. Upper Half (Option 1): Calculate assuming Carry-In = 1
            CSA #(.N(N-K)) upper_half_assume_1 (
                .a(a[N-1:K]),
                .b(b[N-1:K]),
                .ci(1'b1),
                .sum(sum_upper_1),
                .co(co_upper_1)
            );

            // 4. MUX LOGIC (The "Conditional" Part)
            // Use the actual carry from the lower half (co_lower) to select 
            // the correct result for the upper half.
            
            // Lower bits are just passed through
            assign sum[K-1:0] = sum_lower;
            
            // Upper bits: Select between Option 1 and Option 0
            assign sum[N-1:K] = (co_lower) ? sum_upper_1 : sum_upper_0;
            
            // Final Carry: Select between Option 1 and Option 0
            assign co         = (co_lower) ? co_upper_1  : co_upper_0;
        end
    endgenerate

endmodule
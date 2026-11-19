// =============================================================================
// Module: comb_logic_24
// Description:
//   Pure combinational design with exactly 24 logic operations.
//   No clocks, no flip-flops, no sequential elements.
//   I/O budget: 40 inputs + 24 outputs = 64 pins (at the maximum).
// =============================================================================

module comb_logic_24 (
    // ---- 40 inputs ----
    input  wire [7:0] a,          // 8
    input  wire [7:0] b,          // 8
    input  wire [7:0] c,          // 8
    input  wire [3:0] sel,        // 4
    input  wire [7:0] mask,       // 8
    input  wire       en,         // 1
    input  wire       inv_en,     // 1
    input  wire [1:0] mode,       // 2
                                  // ---- total inputs  = 40 ----

    // ---- 24 outputs ----
    output wire [7:0] y0,         // 8
    output wire [7:0] y1,         // 8
    output wire [7:0] y2          // 8
                                  // ---- total outputs = 24 ----
                                  // ---- total I/O     = 64 ----
);

    // -------------------------------------------------------------------------
    // Exactly 24 combinational logic operations
    // -------------------------------------------------------------------------

    // Layer 1 — basic bitwise ops (1..8)
    wire [7:0] t0  = a & b;                          // 1  AND
    wire [7:0] t1  = a | b;                          // 2  OR
    wire [7:0] t2  = a ^ b;                          // 3  XOR
    wire [7:0] t3  = ~(a & b);                       // 4  NAND
    wire [7:0] t4  = ~(a | b);                       // 5  NOR
    wire [7:0] t5  = ~(a ^ b);                       // 6  XNOR
    wire [7:0] t6  = a & mask;                       // 7  masked AND
    wire [7:0] t7  = b | mask;                       // 8  masked OR

    // Layer 2 — shifts / rotates / compares / mux (9..16)
    wire [7:0] t8  = a << 1;                         // 9  left shift
    wire [7:0] t9  = b >> 1;                         // 10 right shift
    wire [7:0] t10 = {a[6:0], a[7]};                 // 11 rotate left
    wire [7:0] t11 = {b[0], b[7:1]};                 // 12 rotate right
    wire [7:0] t12 = sel[0] ? a : b;                 // 13 2:1 mux
    wire [7:0] t13 = sel[1] ? c : t0;                // 14 2:1 mux
    wire [7:0] t14 = (a > b) ? a : b;                // 15 max
    wire [7:0] t15 = (a < b) ? a : b;                // 16 min

    // Layer 3 — combine / enable / mode select (17..24)
    wire [7:0] t16 = t2 ^ c;                         // 17 XOR with c
    wire [7:0] t17 = t6 | t7;                        // 18 OR of masked results
    wire [7:0] t18 = t8 & t9;                        // 19 AND of shifts
    wire [7:0] t19 = t10 ^ t11;                      // 20 XOR of rotates
    wire [7:0] t20 = en ? t12 : 8'h00;               // 21 enable gate
    wire [7:0] t21 = inv_en ? ~t13 : t13;            // 22 optional invert
    wire [7:0] t22 = (mode == 2'b00) ? t14 :
                     (mode == 2'b01) ? t15 :
                     (mode == 2'b10) ? t16 :
                                       t17;          // 23 4:1 mode mux
    wire [7:0] t23 = (sel[3:2] == 2'b00) ? t18 :
                     (sel[3:2] == 2'b01) ? t19 :
                     (sel[3:2] == 2'b10) ? t20 :
                                           t21;      // 24 select mux

    // Outputs — wiring only (no extra logic)
    assign y0 = t22;
    assign y1 = t23;
    assign y2 = t1;

endmodule

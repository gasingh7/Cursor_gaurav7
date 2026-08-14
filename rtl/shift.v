`timescale 1 ps / 1 ps
//----------------------------------------------------------------------
// Wrapper matching the "shift" instance used in top.
// Same behavior as lpm_shiftreg with LEFT direction, width 4.
//----------------------------------------------------------------------
module shift (
    input  wire       clock,
    input  wire       enable,
    input  wire       shiftin,
    input  wire       load,
    input  wire [3:0] data,
    input  wire       sclr,
    input  wire       aclr,
    output wire [3:0] q,
    output wire       shiftout
);

    lpm_shiftreg #(
        .lpm_width(4),
        .lpm_direction("LEFT")
    ) u_impl (
        .clock(clock),
        .enable(enable),
        .shiftin(shiftin),
        .load(load),
        .data(data),
        .sclr(sclr),
        .aclr(aclr),
        .q(q),
        .shiftout(shiftout)
    );

endmodule

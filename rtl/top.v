`timescale 1 ps / 1 ps
module top (
    input  wire       clock_w,    //  lpm_shiftreg_input.clock
    input  wire       enable_w,   //                    .enable
    input  wire       shiftin_w,  //                    .shiftin
    input  wire       load_w,     //                    .load     0=shift, 1=load
    input  wire [3:0] data_w,     //                    .data
    input  wire       sclr_w,     //                    .sclr
    input  wire       aclr_w,     //                    .aclr
    output wire [3:0] q_out,      // lpm_shiftreg_output.q
    output wire       shiftout    //                    .shiftout
);

    wire [3:0] q_w1;
    wire [3:0] q_w2;
    wire       shiftout_w1;
    wire       shiftout_w2;

    shift lpm_shiftreg (
        .clock    (clock_w),
        .enable   (enable_w),
        .shiftin  (shiftin_w),
        .load     (load_w),
        .data     (data_w),
        .sclr     (sclr_w),
        .aclr     (aclr_w),
        .q        (q_w1),
        .shiftout (shiftout_w1)
    );

    lpm_shiftreg #(
        .lpm_width(4),
        .lpm_direction("LEFT")
    ) u_shiftreg (
        .clock(clock_w),
        .enable(enable_w),
        .load(load_w),
        .shiftin(shiftin_w),
        .data(data_w),
        .q(q_w2),
        .shiftout(shiftout_w2),
        .aclr(aclr_w),
        .sclr(sclr_w)
    );

    // Both instances share identical inputs; AND highlights any mismatch.
    assign q_out    = q_w1 & q_w2;
    assign shiftout = shiftout_w1 & shiftout_w2;

endmodule

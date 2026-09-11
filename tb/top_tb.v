`timescale 1ns/1ps

module top_tb;

  reg        clock_w;
  reg        enable_w;
  reg        shiftin_w;
  reg        load_w;
  reg  [3:0] data_w;
  reg        sclr_w;
  reg        sset_w;

  wire       q_out;
  wire       shiftout;

  // DUT
  top dut (
    .clock_w   (clock_w),
    .enable_w  (enable_w),
    .shiftin_w (shiftin_w),
    .load_w    (load_w),
    .data_w    (data_w),
    .sclr_w    (sclr_w),
    .sset_w    (sset_w),
    .q_out     (q_out),
    .shiftout  (shiftout)
  );

  // Clock: 10ns period
  initial clock_w = 0;
  always #5 clock_w = ~clock_w;

  // One-cycle pulse helper
  task automatic pulse_clk;
    begin
      @(posedge clock_w);
    end
  endtask

  // Apply controls and wait one clock
  task automatic apply;
    input        en, si, ld, clr, set;
    input  [3:0] din;
    begin
      enable_w  = en;
      shiftin_w = si;
      load_w    = ld;
      sclr_w    = clr;
      sset_w    = set;
      data_w    = din;
      pulse_clk;
    end
  endtask

  // Simple monitor
  always @(posedge clock_w) begin
    $display("[%0t] q_out=%b  shiftout=%b  load=%b sclr=%b sset=%b shiftin=%b data=%b",
             $time, q_out, shiftout, load_w, sclr_w, sset_w, shiftin_w, data_w);
  end

  initial begin
    // Idle defaults
    enable_w  = 0;
    shiftin_w = 0;
    load_w    = 0;
    data_w    = 4'b0000;
    sclr_w    = 0;
    sset_w    = 0;

    repeat (2) pulse_clk;

    // Parallel load 1010
    apply(1, 0, 1, 0, 0, 4'b1010);

    // Shift: 1, then 0, then 1
    apply(1, 1, 0, 0, 0, 4'b0000);
    apply(1, 0, 0, 0, 0, 4'b0000);
    apply(1, 1, 0, 0, 0, 4'b0000);

    // Sync clear, then sync set
    apply(1, 0, 0, 1, 0, 4'b0000);
    apply(1, 0, 0, 0, 1, 4'b0000);

    // Idle a few cycles
    apply(0, 0, 0, 0, 0, 4'b0000);
    repeat (4) pulse_clk;

    $display("\n******** SIMULATION DONE ********\n");
    $finish;
  end

endmodule

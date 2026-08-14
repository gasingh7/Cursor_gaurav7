`timescale 1 ps / 1 ps
//----------------------------------------------------------------------
// Testbench for top: same stimulus drives BOTH shift-register instances.
// Each test case changes ONE primary control behavior and prints results.
//----------------------------------------------------------------------
module tb_top;

    reg        clock_w;
    reg        enable_w;
    reg        shiftin_w;
    reg        load_w;
    reg  [3:0] data_w;
    reg        sclr_w;
    reg        aclr_w;
    wire [3:0] q_out;
    wire       shiftout;

    integer tc;

    top dut (
        .clock_w  (clock_w),
        .enable_w (enable_w),
        .shiftin_w(shiftin_w),
        .load_w   (load_w),
        .data_w   (data_w),
        .sclr_w   (sclr_w),
        .aclr_w   (aclr_w),
        .q_out    (q_out),
        .shiftout (shiftout)
    );

    // 10 ns period (100 MHz) — timescale 1ps, so #5000 = 5 ns half-period
    initial clock_w = 1'b0;
    always #5000 clock_w = ~clock_w;

    task automatic apply_idle;
        begin
            enable_w  = 1'b0;
            shiftin_w = 1'b0;
            load_w    = 1'b0;
            data_w    = 4'b0000;
            sclr_w    = 1'b0;
            aclr_w    = 1'b0;
        end
    endtask

    task automatic pulse_clk;
        begin
            @(posedge clock_w);
            #1;
        end
    endtask

    task automatic show(input [8*48-1:0] label);
        begin
            $display("  %-40s | en=%0b load=%0b sin=%0b data=%b sclr=%0b aclr=%0b | q_out=%b shiftout=%0b",
                     label, enable_w, load_w, shiftin_w, data_w, sclr_w, aclr_w, q_out, shiftout);
        end
    endtask

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        apply_idle();
        aclr_w = 1'b1;
        #100;
        aclr_w = 1'b0;
        #100;

        // TC1: Asynchronous clear
        tc = 1;
        $display("\n==== TC%0d: Asynchronous Clear (aclr=1) ====", tc);
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1010;
        pulse_clk();
        show("After parallel load of 1010");
        aclr_w = 1'b1;
        #1;
        show("aclr asserted (async) — expect q=0000");
        aclr_w = 1'b0;
        #1;
        show("aclr released — q stays 0000");

        // TC2: Synchronous clear
        tc = 2;
        $display("\n==== TC%0d: Synchronous Clear (sclr=1) ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1111;
        pulse_clk();
        show("Loaded 1111");
        load_w = 1'b0;
        sclr_w = 1'b1;
        pulse_clk();
        show("sclr on posedge — expect q=0000");
        sclr_w = 1'b0;

        // TC3: Parallel load
        tc = 3;
        $display("\n==== TC%0d: Parallel Load (load=1) ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1001;
        pulse_clk();
        show("load data=1001 — expect q=1001, so=1");
        data_w = 4'b0110;
        pulse_clk();
        show("load data=0110 — expect q=0110, so=0");
        load_w = 1'b0;

        // TC4: Serial LEFT shift
        tc = 4;
        $display("\n==== TC%0d: Serial LEFT Shift (load=0) ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b0000;
        pulse_clk();
        show("Reset via load 0000");
        load_w = 1'b0;
        shiftin_w = 1'b1; pulse_clk(); show("shiftin=1");
        shiftin_w = 1'b0; pulse_clk(); show("shiftin=0");
        shiftin_w = 1'b1; pulse_clk(); show("shiftin=1");
        shiftin_w = 1'b1; pulse_clk(); show("shiftin=1 — expect q=1011");

        // TC5: enable=0 hold
        tc = 5;
        $display("\n==== TC%0d: Enable=0 Hold (no update) ====", tc);
        enable_w  = 1'b0;
        shiftin_w = 1'b0;
        load_w    = 1'b1;
        data_w    = 4'b0101;
        sclr_w    = 1'b1;
        pulse_clk();
        show("en=0 with load+sclr — expect HOLD 1011");
        enable_w = 1'b1;
        sclr_w   = 1'b0;
        load_w   = 1'b0;
        shiftin_w= 1'b0;
        pulse_clk();
        show("en=1 shiftin=0 — expect q=0110");

        // TC6: sclr > load priority
        tc = 6;
        $display("\n==== TC%0d: Priority sclr > load ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1100;
        pulse_clk();
        show("Loaded 1100");
        sclr_w = 1'b1;
        load_w = 1'b1;
        data_w = 4'b1111;
        pulse_clk();
        show("sclr+load same cycle — expect q=0000");
        sclr_w = 1'b0;

        // TC7: load > shift priority
        tc = 7;
        $display("\n==== TC%0d: Priority load > shift ====", tc);
        apply_idle();
        enable_w  = 1'b1;
        load_w    = 1'b1;
        data_w    = 4'b0011;
        shiftin_w = 1'b1;
        pulse_clk();
        show("load=1 with shiftin=1 — expect q=0011 not shift");
        load_w = 1'b0;
        pulse_clk();
        show("now shift — expect q=0111");

        // TC8: shiftout = MSB
        tc = 8;
        $display("\n==== TC%0d: shiftout = MSB during LEFT shift ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1000;
        pulse_clk();
        show("Loaded 1000 — expect so=1");
        load_w    = 1'b0;
        shiftin_w = 1'b0;
        pulse_clk();
        show("shift left, sin=0 — expect q=0000 so=0");

        // TC9: aclr mid-operation
        tc = 9;
        $display("\n==== TC%0d: aclr mid-operation ====", tc);
        apply_idle();
        enable_w  = 1'b1;
        load_w    = 1'b1;
        data_w    = 4'b1110;
        pulse_clk();
        show("Loaded 1110");
        load_w = 1'b0;
        shiftin_w = 1'b1;
        #2000;
        aclr_w = 1'b1;
        #1;
        show("aclr mid-cycle — expect q=0000 immediately");
        aclr_w = 1'b0;

        // TC10: dual-instance AND consistency
        tc = 10;
        $display("\n==== TC%0d: Dual-instance AND consistency ====", tc);
        apply_idle();
        enable_w = 1'b1;
        load_w   = 1'b1;
        data_w   = 4'b1010;
        pulse_clk();
        show("Both loaded same — q_out must equal 1010");
        if (q_out !== 4'b1010)
            $display("  FAIL: expected 1010, got %b", q_out);
        else
            $display("  PASS: dual instances match (q_out = q_w1 & q_w2)");

        $display("\n==== All directed test cases complete ====\n");
        #20000;
        $finish;
    end

endmodule

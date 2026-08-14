`timescale 1 ps / 1 ps
//----------------------------------------------------------------------
// Behavioral model of Altera/Intel LPM_SHIFTREG (LEFT, width=4)
// Priority on enabled clock edge: sclr > load > shift
// aclr is asynchronous (active-high).
//----------------------------------------------------------------------
module lpm_shiftreg #(
    parameter lpm_width     = 4,
    parameter lpm_direction = "LEFT"
) (
    input  wire                      clock,
    input  wire                      enable,
    input  wire                      shiftin,
    input  wire                      load,
    input  wire [lpm_width-1:0]      data,
    input  wire                      sclr,
    input  wire                      aclr,
    output reg  [lpm_width-1:0]      q,
    output wire                      shiftout
);

    // For LEFT:  shiftout is MSB; for RIGHT: shiftout is LSB
    assign shiftout = (lpm_direction == "LEFT") ? q[lpm_width-1] : q[0];

    always @(posedge clock or posedge aclr) begin
        if (aclr) begin
            q <= {lpm_width{1'b0}};
        end else if (enable) begin
            if (sclr) begin
                q <= {lpm_width{1'b0}};
            end else if (load) begin
                q <= data;
            end else begin
                if (lpm_direction == "LEFT")
                    q <= {q[lpm_width-2:0], shiftin};   // shiftin -> LSB
                else
                    q <= {shiftin, q[lpm_width-1:1]};   // shiftin -> MSB
            end
        end
    end

endmodule

module cordic_dut_uvm #(
    parameter int MODE = 0,
    parameter int XY_W = 16,
    parameter int ANGLE_W = 32,
    parameter int ITER = 16,
    parameter int GUARD = 3,
    parameter int GAIN_COMP = 0
)(
    input logic clk,
    input logic rst_n,
    input logic in_valid,
    output logic in_ready,
    input logic signed [XY_W-1:0] x_in,
    input logic signed [XY_W-1:0] y_in,
    input logic signed [ANGLE_W-1:0] z_in,
    output logic out_valid,
    input logic out_ready,
    output logic signed [XY_W-1:0] cos_out,
    output logic signed [XY_W-1:0] sin_out,
    output logic signed [XY_W-1:0] mag_out,
    output logic signed [ANGLE_W-1:0] theta_out
);

    generate
        if (MODE == 0) begin : g_rot
            cordic_rotator #(
                .XY_W(XY_W),
                .ANGLE_W(ANGLE_W),
                .ITER(ITER),
                .GUARD(GUARD),
                .GAIN_COMP(GAIN_COMP)
            ) u_rotator (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(),
                .in_ready(),
                .x_start(x_in),
                .y_start(y_in),
                .angle(z_in),
                .out_valid(),
                .out_ready(),
                .cosine(cos_out),
                .sine(sin_out)
            );
            assign mag_out = '0;
            assign theta_out = '0;
        end else begin : g_vec
            cordic_vectoring #(
                .XY_W(XY_W),
                .ANGLE_W(ANGLE_W),
                .ITER(ITER),
                .GUARD(GUARD),
                .GAIN_COMP(GAIN_COMP)
            ) u_vectoring (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(),
                .in_ready(),
                .x_start(x_in),
                .y_start(y_in),
                .out_valid(),
                .out_ready(),
                .mag(mag_out),
                .theta(theta_out)
            );
            assign cos_out = '0;
            assign sin_out = '0;
        end
    endgenerate

endmodule
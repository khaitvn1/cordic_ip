interface cordic_if #(int XY_W = 16, int ANGLE_W = 32)(input logic clk);
    logic rst_n;
    logic in_valid;
    logic in_ready;
    logic signed [XY_W-1:0] x_in, y_in;
    logic signed [ANGLE_W-1:0] z_in;
    logic out_valid;
    logic out_ready;
    logic signed [XY_W-1:0] cos_out, sin_out, mag_out;
    logic signed [ANGLE_W-1:0] theta_out;

    clocking drv_cb @(posedge clk);
        output in_valid, x_in, y_in, z_in, out_ready;
        input in_ready, out_valid;
    endclocking

    clocking mon_cb @(posedge clk);
        input rst_n, in_valid, in_ready, x_in, y_in, z_in;
        input out_valid, out_ready, cos_out, sin_out, mag_out, theta_out;
    endclocking

    modport drv (clocking drv_cb);
    modport mon (clocking mon_cb);
endinterface
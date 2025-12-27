module cordic_vectoring #(
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
    input logic signed [XY_W-1:0] x_start,
    input logic signed [XY_W-1:0] y_start,
    output logic out_valid,
    input logic out_ready,
    output logic signed [XY_W-1:0] mag,
    output logic signed [ANGLE_W-1:0] theta
);
    import cordic_pkg::*;

    logic stall;
    logic accept;
    assign stall = out_valid && !out_ready;
    assign in_ready = !stall;
    assign accept = in_valid && in_ready;

    // valid pipeline (same as rotator)
    logic [ITER:0] vld;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld <= '0;
        end else if (!stall) begin
            vld <= {vld[ITER-1:0], accept};
        end
    end
    assign out_valid = vld[ITER];

    localparam int XYI = XY_W + GUARD;
    logic signed [XYI:0] x0, y0;
    logic signed [ANGLE_W-1:0] z0;

    // VECTORING preproc: make x0>=0 and seed z0 with 0 / ±pi / ±pi/2 for full atan2
    cordic_preproc_vec #(
        .XY_W(XY_W),
        .XYI(XYI),
        .ANGLE_W(ANGLE_W)
    ) u_preproc_vec (
        .clk(clk),
        .rst_n(rst_n),
        .ce(!stall),
        .load(accept),
        .x_in(x_start),
        .y_in(y_start),
        .x0(x0),
        .y0(y0),
        .z0(z0)
    );

    // pipeline arrays
    logic signed [XYI:0] x_pipe [0:ITER];
    logic signed [XYI:0] y_pipe [0:ITER];
    logic signed [ANGLE_W-1:0] z_pipe [0:ITER];

    assign x_pipe[0] = x0;
    assign y_pipe[0] = y0;
    assign z_pipe[0] = z0;

    // CORDIC pipeline stages in VECTORING mode
    genvar i;
    generate
        for (i = 0; i < ITER; i++) begin : STG
            cordic_stage #(
                .XYI(XYI),
                .ANGLE_W(ANGLE_W),
                .I(i),
                .MODE(1'b1)
            ) u_stage (
                .clk(clk),
                .rst_n(rst_n),
                .ce(!stall),
                .x_in(x_pipe[i]),
                .y_in(y_pipe[i]),
                .z_in(z_pipe[i]),
                .x_out(x_pipe[i+1]),
                .y_out(y_pipe[i+1]),
                .z_out(z_pipe[i+1])
            );
        end
    endgenerate

    logic signed [XYI:0] mag_raw;
    assign mag_raw = x_pipe[ITER];

    localparam int MULT_W = (XYI+1) + 16;
    logic signed [MULT_W-1:0] mag_prod;
    logic signed [XYI:0] mag_sc;
    logic signed [XYI:0] mag_sel;

    always_comb begin
        mag_prod = $signed(mag_raw) * $signed(KINV_Q15);
        mag_sc = $signed(mag_prod >>> KINV_SHIFT);
        mag_sel = (GAIN_COMP != 0) ? mag_sc : mag_raw;
    end

    assign mag = mag_sel[XY_W-1:0];
    assign theta = z_pipe[ITER];

endmodule

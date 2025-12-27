module cordic_rotator #(
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
    input logic signed [ANGLE_W-1:0] angle,
    output logic out_valid,
    input logic out_ready,
    output logic signed [XY_W-1:0] cosine,
    output logic signed [XY_W-1:0] sine
);
    import cordic_pkg::*;

    logic stall;
    logic accept;
    assign stall = out_valid && !out_ready;
    assign in_ready = !stall;
    assign accept = in_valid && in_ready;
    
    // vld[0] is the sample stored in preproc output regs (x0/y0/z0)
    // out_valid = vld[ITER], which is the sample in the last preproc output regs
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
    logic signed [XYI:0] x0;
    logic signed [XYI:0] y0;
    logic signed [ANGLE_W-1:0] z0;
    
    // Preproc only updates when we accept a new input sample, and not stalled.
    cordic_preproc #(
        .XY_W(XY_W),
        .XYI(XYI),
        .ANGLE_W(ANGLE_W)
    ) u_preproc (
        .clk(clk),
        .rst_n(rst_n),
        .ce(!stall),
        .load(accept),
        .x_in(x_start),
        .y_in(y_start),
        .angle_in(angle),
        .x0(x0),
        .y0(y0),
        .z0(z0)
    );
    
    // Stage pipeline registers
    logic signed [XYI:0] x_pipe [0:ITER];
    logic signed [XYI:0] y_pipe [0:ITER];
    logic signed [ANGLE_W-1:0] z_pipe [0:ITER];
    
    assign x_pipe[0] = x0;
    assign y_pipe[0] = y0;
    assign z_pipe[0] = z0;

    // CORDIC pipeline stages
    genvar i;
    generate
        for (i = 0; i < ITER; i++) begin : STG
            cordic_stage #(
                .XYI(XYI),
                .ANGLE_W(ANGLE_W),
                .I(i),
                .MODE(1'b0) 
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
    
    // raw outputs from last stage
    logic signed [XYI:0] cos_raw, sin_raw;
    assign cos_raw = x_pipe[ITER];
    assign sin_raw = y_pipe[ITER];
    
    // gain compensation
    localparam int MULT_W = (XYI+1) + 16;
    logic signed [MULT_W-1:0] cos_prod, sin_prod;
    logic signed [XYI:0] cos_sc, sin_sc;
    
    always_comb begin
        cos_prod = $signed(cos_raw) * $signed(KINV_Q15);
        sin_prod = $signed(sin_raw) * $signed(KINV_Q15);
        cos_sc = $signed(cos_prod >>> KINV_SHIFT);
        sin_sc = $signed(sin_prod >>> KINV_SHIFT);
    end
    
    logic signed [XYI:0] cos_sel, sin_sel;
    always_comb begin
      if (GAIN_COMP) begin
        cos_sel = cos_sc;
        sin_sel = sin_sc;
      end else begin
        cos_sel = cos_raw;
        sin_sel = sin_raw;
      end
    end
    
    assign cosine = cos_sel[XY_W-1:0];
    assign sine = sin_sel[XY_W-1:0];

endmodule

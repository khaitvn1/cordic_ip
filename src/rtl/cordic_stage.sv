module cordic_stage #(
    parameter int XYI = 19,
    parameter int ANGLE_W = 32,
    parameter int I = 0,
    parameter logic MODE = 1'b0 // 0 = ROTATION, 1 = VECTORING
)(
    input logic clk,
    input logic rst_n,
    input logic ce,
    input logic signed [XYI:0] x_in,
    input logic signed [XYI:0] y_in,
    input logic signed [ANGLE_W-1:0] z_in,
    output logic signed [XYI:0] x_out,
    output logic signed [XYI:0] y_out,
    output logic signed [ANGLE_W-1:0] z_out
);
    import cordic_pkg::*;
    
    typedef enum logic {MODE_ROT = 1'b0, MODE_VEC = 1'b1} cordic_mode_e;
    
    logic signed [XYI:0] x_shr;
    logic signed [XYI:0] y_shr;
    logic signed [ANGLE_W-1:0] atan_i;
    logic dir;
    
    always_comb begin
        x_shr = x_in >>> I;
        y_shr = y_in >>> I;
        atan_i = $signed(cordic_pkg::atan_lut(I));
        dir = (MODE == MODE_ROT) ? z_in[ANGLE_W-1] : y_in[XYI];
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_out <= '0;
            y_out <= '0;
            z_out <= '0;
        end else if (ce) begin
            if (MODE == MODE_ROT) begin
                // rotation mode (drives z -> 0)
                x_out <= dir ? (x_in + y_shr) : (x_in - y_shr);
                y_out <= dir ? (y_in - x_shr) : (y_in + x_shr);
                z_out <= dir ? (z_in + atan_i) : (z_in - atan_i);
            end else begin
                // vectoring mode (drives y -> 0)
                x_out <= dir ? (x_in - y_shr) : (x_in + y_shr);
                y_out <= dir ? (y_in + x_shr) : (y_in - x_shr);
                z_out <= dir ? (z_in - atan_i) : (z_in + atan_i);
            end
        end
      end
    
endmodule
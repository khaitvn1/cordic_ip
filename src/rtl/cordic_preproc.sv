module cordic_preproc #(
  parameter int XY_W = 16,
  parameter int XYI = 19,
  parameter int ANGLE_W = 32
)(
  input logic clk,
  input logic rst_n,
  input logic ce,
  input logic load,
  input logic signed [XY_W-1:0] x_in,
  input logic signed [XY_W-1:0] y_in,
  input logic [ANGLE_W-1:0] angle_in,
  output logic signed [XYI:0] x0,
  output logic signed [XYI:0] y0,
  output logic signed [ANGLE_W-1:0] z0
);
  import cordic_pkg::*;
    
  logic signed [ANGLE_W-1:0] ang_s;
  logic [1:0] quadrant;
  logic signed [XYI:0] x_ext, y_ext;

  always_comb begin
    ang_s = $signed(angle_in);
    quadrant = ang_s[ANGLE_W-1 -: 2];

    x_ext = {{(XYI-XY_W+1){x_in[XY_W-1]}}, x_in};
    y_ext = {{(XYI-XY_W+1){y_in[XY_W-1]}}, y_in};
  end
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x0 <= '0;
      y0 <= '0;
      z0 <= '0;
    end else if (ce) begin
      if (load) begin
        unique case (quadrant)
          2'b00, 2'b11: begin
            x0 <= x_ext;
            y0 <= y_ext;
            z0 <= ang_s;
          end
          2'b01: begin
            x0 <= -y_ext;
            y0 <= x_ext;
            z0 <= ang_s - $signed(cordic_pkg::ANG_PI_2);
          end
          2'b10: begin
            x0 <= y_ext;
            y0 <= -x_ext;
            z0 <= ang_s + $signed(cordic_pkg::ANG_PI_2);
          end
        endcase
      end
    end
  end
endmodule
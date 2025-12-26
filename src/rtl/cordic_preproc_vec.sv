module cordic_preproc_vec #(
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
  output logic signed [XYI:0] x0,
  output logic signed [XYI:0] y0,
  output logic signed [ANGLE_W-1:0] z0
);
  import cordic_pkg::*;

  logic signed [XYI:0] x_ext, y_ext;

  always_comb begin
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
        if (x_ext == 0) begin
          x0 <= (y_ext < 0) ? -y_ext : y_ext;
          y0 <= '0;
          z0 <= (y_ext < 0) ? -$signed(ANG_PI_2) : $signed(ANG_PI_2);
        end else if (x_ext < 0) begin
          x0 <= -x_ext;
          y0 <= -y_ext;
          z0 <= (y_ext < 0) ? -$signed(ANG_PI) : $signed(ANG_PI);
        end else begin
          x0 <= x_ext;
          y0 <= y_ext;
          z0 <= '0;
        end
      end
    end
  end
endmodule

`timescale 1ns/1ps

module tb_cordic_rotator;

  localparam int XY_W = 16;
  localparam int ANGLE_W = 32;
  localparam int ITER = 16;
  localparam int GUARD = 3;

  // 0 = no gain compensation, 1 = gain compensation
  localparam int GAIN_COMP = 1;
  localparam int OUT_AMP = 30000;

  // CORDIC gain (approx): only used when GAIN_COMP == 0
  real K = 1.646760258;

  logic clk;
  logic rst_n;

  logic in_valid;
  logic in_ready;
  logic signed [XY_W-1:0] x_in, y_in;
  logic [ANGLE_W-1:0] angle;
  logic out_valid;
  logic out_ready;
  logic signed [XY_W-1:0] cos_out, sin_out;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  // degrees to 32-bit "binary angle" (2^32 = 360 degrees)
  function automatic logic [ANGLE_W-1:0] deg_to_angle(input real deg);
    longint signed a;
    real scaled;
    begin
      scaled = deg * (4.294967296e9 / 360.0); // 2^32 / 360
      a = $rtoi(scaled);
      deg_to_angle = a[ANGLE_W-1:0];
    end
  endfunction

  function automatic bit has_x(input logic [XY_W-1:0] v);
    begin
      has_x = $isunknown(v);
    end
  endfunction

  // send one sample
  task automatic send_one(input real deg, input int signed x_amp, input int signed y_amp);
    real deg_eff;
    begin
      deg_eff = (deg >= 180.0) ? (deg - 360.0) : deg;

      @(negedge clk);
      angle = deg_to_angle(deg_eff);
      x_in = x_amp[XY_W-1:0];
      y_in = y_amp[XY_W-1:0];
      in_valid = 1'b1;

      $display("DRIVE: deg=%0.3f angle=0x%08h x_in=%0d y_in=%0d", deg, angle, x_in, y_in);

      while (!(in_valid && in_ready)) @(posedge clk);

      @(negedge clk);
      in_valid = 1'b0;
    end
  endtask

  // receive one sample (plus stalling test on output ready)
  task automatic receive_one(input int stall_prob_percent, output logic signed [XY_W-1:0] got_c, output logic signed [XY_W-1:0] got_s);
    int cyc;
    begin
      got_c = 'x;
      got_s = 'x;
      cyc = 0;

      // random stall on output ready
      forever begin
        @(negedge clk);
        out_ready = (($urandom_range(0,99)) >= stall_prob_percent);

        @(posedge clk);
        cyc++;

        if (cyc <= 5 || (cyc % 8 == 0))
          $display("WAIT: cyc=%0d in_v/r=%0b/%0b out_v/r=%0b/%0b cos=%0d sin=%0d", cyc, in_valid, in_ready, out_valid, out_ready, cos_out, sin_out);

        if (out_valid && out_ready) begin
          got_c = cos_out;
          got_s = sin_out;

          @(negedge clk);
          out_ready = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic run_test(input real deg);
    int exp_c, exp_s;
    real rad;
    int tol;

    int signed x_amp;
    logic signed [XY_W-1:0] got_c, got_s;

    begin
      // If the DUT does NOT do gain compensation, we pre-scale x by 1/K.
      // If the DUT DOES do gain compensation, we drive the full desired amplitude.
      if (GAIN_COMP != 0) begin
        x_amp = OUT_AMP;
      end else begin
        x_amp = $rtoi(OUT_AMP / K);
      end

      if ((in_ready === 1'bx) || (out_valid === 1'bx)) begin
        $fatal(1, "Handshake signals are X before sending input. Check reset polarity/connection.");
      end

      send_one(deg, x_amp, 0);
      receive_one(got_c, got_s, 0);

      if (has_x(got_c) || has_x(got_s)) begin
        $display("FAIL: Captured X on output: got_c=%b got_s=%b", got_c, got_s);
        $fatal(1, "DUT outputs are X at handshake.");
      end

      rad = deg * 3.14159265358979323846 / 180.0;
      exp_c = $rtoi(OUT_AMP * $cos(rad));
      exp_s = $rtoi(OUT_AMP * $sin(rad));

      tol = 300;

      $display("RESULT: got(c,s)=(%0d,%0d) exp(c,s)=(%0d,%0d)", $signed(got_c), $signed(got_s), exp_c, exp_s);

      if (($signed(got_c) < exp_c - tol) || ($signed(got_c) > exp_c + tol) || ($signed(got_s) < exp_s - tol) || ($signed(got_s) > exp_s + tol)) begin
        $display("FAIL: (tol=%0d)", tol);
      end else begin
        $display("PASS: (tol=%0d)", tol);
      end

    end
  endtask

  cordic_rotator #(
    .XY_W(XY_W),
    .ANGLE_W(ANGLE_W),
    .ITER(ITER),
    .GUARD(GUARD),
    .GAIN_COMP(GAIN_COMP)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_ready(in_ready),
    .x_start(x_in),
    .y_start(y_in),
    .angle(angle),
    .out_valid(out_valid),
    .out_ready(out_ready),
    .cosine(cos_out),
    .sine(sin_out)
  );

  initial begin
    rst_n = 1'b0;
    in_valid = 1'b0;
    x_in = '0;
    y_in = '0;
    angle = '0;
    out_ready = 1'b1;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    $display("Rotation tests simulation started");

    run_test(0.0);
    run_test(30.0);
    run_test(45.0);
    run_test(60.0);
    run_test(90.0);
    run_test(135.0);
    run_test(180.0);
    run_test(315.0);

    $display("Simulation done");
    $finish;
  end

endmodule


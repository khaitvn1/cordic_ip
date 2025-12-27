`timescale 1ns/1ps

module tb_cordic_vectoring;

  localparam int XY_W = 16;
  localparam int ANGLE_W = 32;
  localparam int ITER = 16;
  localparam int GUARD = 3;
  localparam int GAIN_COMP = 1; // 1 => mag ≈ hypot(x,y); 0 => mag ≈ K*hypot(x,y)

  logic clk;
  logic rst_n;

  logic in_valid;
  logic in_ready;
  logic signed [XY_W-1:0] x_in, y_in;
  logic out_valid;
  logic out_ready;
  logic signed [XY_W-1:0] mag_out;
  logic signed [ANGLE_W-1:0] theta_out;

  initial clk = 1'b0;
  always #5 clk = ~clk;

  // 2^32 "turns" to radians
  function automatic real angle_to_rad(input logic signed [ANGLE_W-1:0] ang);
    real turns;
    begin
      turns = $itor($signed(ang)) / 4294967296.0; // 2^32
      angle_to_rad = turns * 2.0 * 3.14159265358979323846;
    end
  endfunction

  // radians to 2^32 "turns"
  function automatic logic signed [ANGLE_W-1:0] rad_to_angle(input real rad);
    real turns;
    real scaled;
    longint signed a;
    begin
      turns = rad / (2.0 * 3.14159265358979323846);
      scaled = turns * 4294967296.0; // 2^32
      a = $rtoi(scaled);
      rad_to_angle = a[ANGLE_W-1:0];
    end
  endfunction

  // check to see if there's any X in magnitude (initialized problem)
  function automatic bit has_x_vec(input logic [XY_W-1:0] v);
    begin
      has_x_vec = $isunknown(v);
    end
  endfunction

  // check to see if there's any X in angle (initialized problem)
  function automatic bit has_x_ang(input logic [ANGLE_W-1:0] v);
    begin
      has_x_ang = $isunknown(v);
    end
  endfunction

  // send 1 sample
  task automatic send_one(input int signed x, input int signed y);
    begin
      @(negedge clk);
      x_in = x[XY_W-1:0];
      y_in = y[XY_W-1:0];
      in_valid = 1'b1;

      $display("DRIVE: x=%0d y=%0d", $signed(x_in), $signed(y_in));

      while (!(in_valid && in_ready)) @(posedge clk);

      @(negedge clk);
      in_valid = 1'b0;
    end
  endtask

  // receive 1 sample
  task automatic receive_one(input int stall_prob_percent, output logic signed [XY_W-1:0] got_m, output logic signed [ANGLE_W-1:0] got_th);
    int cyc;
    begin
      got_m = 'x;
      got_th = 'x;
      cyc = 0;

      // random stall on output ready (plus stalling test on output ready)
      forever begin
        @(negedge clk);
        out_ready = (($urandom_range(0,99)) >= stall_prob_percent);

        @(posedge clk);
        cyc++;

        if (cyc <= 5 || (cyc % 8 == 0)) begin
          $display("WAIT: cyc=%0d in_v/r=%0b/%0b out_v/r=%0b/%0b mag=%0d theta=0x%08h", cyc, in_valid, in_ready, out_valid, out_ready, $signed(mag_out), theta_out);
        end

        if (out_valid && out_ready) begin
          got_m  = mag_out;
          got_th = theta_out;

          @(negedge clk);
          out_ready = 1'b1;
          break;
        end
      end
    end
  endtask

  task automatic run_test(input int signed x, input int signed y);
    logic signed [XY_W-1:0] got_m;
    logic signed [ANGLE_W-1:0] got_th;

    real exp_mag_r;
    real exp_th_r;
    real got_th_r;
    real diff;
    int exp_mag_i;

    int tol_mag;
    real tol_th;

    begin
      // avoid 0, 0 for atan2 (undefined)
      if (x == 0 && y == 0) begin
        $display("SKIP: x=0, y=0");
        return;
      end

      if ((in_ready === 1'bx) || (out_valid === 1'bx)) begin
        $fatal(1, "Handshake signals are X before sending input. Check reset wiring/polarity.");
      end

      send_one(x, y);
      receive_one(got_m, got_th, 25);

      if (has_x_vec(got_m) || has_x_ang(got_th)) begin
        $display("FAIL: Captured X on output: mag=%b theta=%b", got_m, got_th);
        $fatal(1, "DUT outputs are X at handshake.");
      end

      // expected magnitude/angle
      exp_mag_r = $sqrt($itor(x)*$itor(x) + $itor(y)*$itor(y));
      exp_th_r = $atan2($itor(y), $itor(x));

      got_th_r = angle_to_rad(got_th);

      // Wrap-aware angle difference into [-pi, +pi]
      diff = got_th_r - exp_th_r;
      while (diff > 3.14159265358979323846) diff -= 2.0*3.14159265358979323846;
      while (diff < -3.14159265358979323846) diff += 2.0*3.14159265358979323846;

      // magnitude expectation depends on gain comp
      if (GAIN_COMP != 0) begin
        exp_mag_i = $rtoi(exp_mag_r);
      end else begin
        // if not gain-comped, mag ≈ K * hypot(x,y)
        exp_mag_i = $rtoi(1.646760258 * exp_mag_r);
      end

      // tolerances
      tol_mag = 700;
      tol_th = 0.01;

      $display("RESULT: got_mag=%0d exp_mag=%0d | got_th=0x%08h diff_rad=%0.6f", $signed(got_m), exp_mag_i, got_th, diff);

      if (($signed(got_m) < exp_mag_i - tol_mag) || ($signed(got_m) > exp_mag_i + tol_mag)) begin
        $display("FAIL MAG: tol=%0d", tol_mag);
        $fatal(1, "Magnitude check failed");
      end

      if ((diff < -tol_th) || (diff > tol_th)) begin
        $display("FAIL ANG: tol_rad=%0.6f", tol_th);
        $fatal(1, "Angle check failed");
      end

      $display("PASS");
    end
  endtask

  cordic_vectoring #(
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
    .out_valid(out_valid),
    .out_ready(out_ready),
    .mag(mag_out),
    .theta(theta_out)
  );

  initial begin
    rst_n = 1'b0;
    in_valid = 1'b0;
    x_in = '0;
    y_in = '0;
    out_ready = 1'b1;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    $display("Vectoring tests simulation started");

    // Quadrant tests
    run_test(20000, 10000); // Q1
    run_test(-20000, 10000); // Q2
    run_test(-20000, -10000); // Q3
    run_test(20000, -10000); // Q4

    // Axis tests
    run_test(0, 20000); // +Y
    run_test(0, -20000); // -Y
    run_test(20000, 0); // +X
    run_test(-20000, 0); // -X

    $display("Simulation done: PASS");
    $finish;
  end

endmodule

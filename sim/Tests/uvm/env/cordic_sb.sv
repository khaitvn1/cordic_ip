import uvm_pkg::*;
`include "uvm_macros.svh"
import cordic_pkg::*;
import cordic_tb_pkg::*;

class cordic_sb extends uvm_scoreboard;
    `uvm_component_utils(cordic_sb)
    uvm_analysis_imp #(cordic_seq_item, cordic_sb) item_collect_export;

    cordic_cfg cfg;

    int num_in, num_correct, num_incorrect;

    localparam real PI = 3.14159265358979323846;

    function new(string name="cordic_sb", uvm_component parent=null);
        super.new(name, parent);
        item_collect_export = new("item_collect_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(cordic_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "cordic_sb: missing cordic_cfg (set via config_db in tb_top/test)")
        end
    endfunction

    function int abs_i(int v);
        return (v < 0) ? -v : v;
    endfunction

    // Q1 to 15 (avoid casts)
    function real q1_15_to_real(logic signed [15:0] q);
        return real'($signed(q)) / 32768.0;
    endfunction

    function int real_to_q1_15_int(real r);
        // Return as int (LSBs). HW may overflow/wrap;
        return $rtoi(r * 32768.0);
    endfunction

    // Angle format: pi == 0x8000_0000 => rad = ang * pi / 2^31
    function real ang32_to_rad(logic signed [31:0] ang);
        return real'($signed(ang)) * PI / (2.0**31);
    endfunction

    function logic signed [31:0] rad_to_ang32(real rad);
        real scaled;
        // clamp to [-pi, pi)
        if (rad >= PI) begin
            rad = rad - 2.0*PI;
        end else if (rad < -PI) begin
            rad = rad + 2.0*PI;
        end
        scaled = rad * (2.0**31) / PI;
        return $signed($rtoi(scaled));
    endfunction

    // Wrap-safe unsigned distance between two 32-bit angles
    function longint unsigned ang_dist32(logic [31:0] a, logic [31:0] b);
        longint unsigned ua, ub, d;
        ua = {32'd0, a};
        ub = {32'd0, b};
        d  = (ua - ub) & 64'hFFFF_FFFF;
        if (d > 64'h8000_0000) begin 
            d = 64'h1_0000_0000 - d;
        end
        return d;
    endfunction

    function real gain_factor();
        // DUT uses KINV_Q15 to COMPENSATE if GAIN_COMP==1
        // If gain_comp enabled => outputs match true math => g=1
        // Else => outputs include CORDIC gain K = 1/kinv
        real kinv;
        kinv = real'($signed(cordic_pkg::KINV_Q15)) / (2.0**cordic_pkg::KINV_SHIFT);
        if (cfg.gain_comp) begin 
            return 1.0;
        end else begin
            return 1.0 / kinv;
        end
    endfunction

    function void write(cordic_seq_item tr);
        real xr, yr, th, g;
        real out_xr, out_yr, out_mag;

        int exp_cos_i, exp_sin_i, exp_mag_i;
        int got_cos_i, got_sin_i, got_mag_i;

        logic signed [31:0] exp_theta;
        longint unsigned dth;

        int dc, ds, dm;

        logic signed [15:0] exp_cos_w, exp_sin_w, exp_mag_w;

        num_in++;

        xr = q1_15_to_real(tr.x_in);
        yr = q1_15_to_real(tr.y_in);
        g  = gain_factor();

        if (cfg.mode == CORDIC_ROT) begin
            th = ang32_to_rad(tr.z_in);

            // expected rotated vector (and include gain if cfg.gain_comp==0)
            out_xr = (xr*$cos(th) - yr*$sin(th)) * g;
            out_yr = (xr*$sin(th) + yr*$cos(th)) * g;

            exp_cos_i = real_to_q1_15_int(out_xr);
            exp_sin_i = real_to_q1_15_int(out_yr);

            exp_cos_w = exp_cos_i[15:0];
            exp_sin_w = exp_sin_i[15:0];

            got_cos_i = $signed(tr.cos_out);
            got_sin_i = $signed(tr.sin_out);

            dc = abs_i(got_cos_i - $signed(exp_cos_w));
            ds = abs_i(got_sin_i - $signed(exp_sin_w));

            if (dc <= cfg.tol_xy_lsb && ds <= cfg.tol_xy_lsb) begin
                num_correct++;
            end else begin
                num_incorrect++;
                `uvm_error("CORDIC_SB",
                $sformatf("ROT FAIL: x=%0d y=%0d z=0x%08h exp(c,s)=(%0d,%0d) got=(%0d,%0d) dc=%0d ds=%0d tol=%0d gain_comp=%0d",
                    $signed(tr.x_in), $signed(tr.y_in), tr.z_in,
                    $signed(exp_cos_w), $signed(exp_sin_w),
                    got_cos_i, got_sin_i,
                    dc, ds, cfg.tol_xy_lsb, cfg.gain_comp))
            end
        end else begin // CORDIC_VEC
            out_mag   = $sqrt(xr*xr + yr*yr) * g;
            exp_mag_i = real_to_q1_15_int(out_mag);

            exp_mag_w = exp_mag_i[15:0];

            got_mag_i = $signed(tr.mag_out);
            dm = abs_i(got_mag_i - $signed(exp_mag_w));

            exp_theta = rad_to_ang32($atan2(yr, xr));
            dth       = ang_dist32(tr.theta_out, exp_theta);

            if (dm <= cfg.tol_xy_lsb && dth <= longint'(cfg.tol_theta_lsb)) begin
                num_correct++;
            end else begin
                num_incorrect++;
                `uvm_error("CORDIC_SB",
                $sformatf("VEC FAIL: x=%0d y=%0d exp(mag,theta)=(%0d,0x%08h) got=(%0d,0x%08h) dm=%0d tol_m=%0d dth=%0d tol_th=%0d gain_comp=%0d",
                    $signed(tr.x_in), $signed(tr.y_in),
                    $signed(exp_mag_w), exp_theta,
                    got_mag_i, tr.theta_out,
                    dm, cfg.tol_xy_lsb, dth, cfg.tol_theta_lsb, cfg.gain_comp))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard: Total=%0d Correct=%0d Incorrect=%0d", num_in, num_correct, num_incorrect), UVM_LOW)

        if (num_incorrect > 0) begin
            `uvm_error(get_type_name(), "Simulation FAILED")
        end else begin
            `uvm_info(get_type_name(), "Simulation PASSED", UVM_LOW)
        end
    endfunction

endclass : cordic_sb
// top-level wrapper for CORDIC rotator and vectoring IP cores (Basys3 (Xilinx Artix-7) demo)

module cordic_top (
    input logic clk,
    input logic [15:0] sw,
    input logic btnC,
    input logic btnU,
    output logic [15:0] led,
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic dp
);

    logic rst_n;
    assign rst_n = ~btnU;

    // Mode select
    logic mode_vec; // 0 = rotation, 1 = vectoring
    logic show_b; // sin/cos for rotation or mag/theta for vectoring
    assign mode_vec = sw[0];
    assign show_b = sw[1];

    // Debounce + edge-detect for btnC

    // double-flop to sync btnC to clk
    logic btnC_ff1, btnC_ff2;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btnC_ff1 <= 1'b0;
            btnC_ff2 <= 1'b0;
        end else begin
            btnC_ff1 <= btnC;
            btnC_ff2 <= btnC_ff1;
        end
    end

    // simple debouncer: sample at ~1kHz using a counter, require N consecutive highs
    logic [16:0] db_cnt; // ~100e6 / 2^17 ≈ 763 Hz sample
    logic db_tick;
    assign db_tick = (db_cnt == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            db_cnt <= '0;
        end else begin 
            db_cnt <= db_cnt + 1'b1;
        end
    end

    logic [7:0] btnC_prev;
    logic btnC_debounced;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btnC_prev <= 8'h00;
            btnC_debounced <= 1'b0;
        end else if (db_tick) begin
            btnC_prev <= {btnC_prev[6:0], btnC_ff2};
            // debounced high if all 1s, low if all 0s, else hold previous
            if (&btnC_prev) begin
                btnC_debounced <= 1'b1;
            end else if (~|btnC_prev) begin
                btnC_debounced <= 1'b0;
            end
        end
    end

    logic btnC_deb_prev, start_pulse;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btnC_deb_prev <= 1'b0;
        end else begin
            btnC_deb_prev <= btnC_debounced;
        end
    end
    assign start_pulse = btnC_debounced & ~btnC_deb_prev; // rising edge detect

    // Build input words from switches
    //
    // Rotation mode:
    // x_start = signed(sw[15:8]) << 8 (scaled 8-bit signed)
    // y_start = 0
    // angle = sw[7:0] mapped to 0..2π in 256 steps: {sw[7:0], 24'b0}
    //
    // Vectoring mode:
    // x_start = signed(sw[15:8]) << 8
    // y_start = signed(sw[7:0]) << 8
    logic signed [15:0] x_sw, y_sw;
    logic signed [15:0] x_in_rot, y_in_rot;
    logic signed [15:0] x_in_vec, y_in_vec;
    logic signed [31:0] angle_rot;

    assign x_sw = $signed({sw[15:8], 8'b0}); // sign-extend 8-bit then scale
    assign y_sw = $signed({sw[7:0],  8'b0});

    assign x_in_rot = x_sw;
    assign y_in_rot = '0;
    assign angle_rot = $signed({sw[7:0], 24'b0});

    assign x_in_vec = x_sw;
    assign y_in_vec = y_sw;
    
    logic rot_in_valid, rot_in_ready, rot_out_valid;
    logic vec_in_valid, vec_in_ready, vec_out_valid;

    logic rot_accept, vec_accept;
    logic pending;

    assign rot_in_valid = pending && !mode_vec;
    assign vec_in_valid = pending && mode_vec;

    assign rot_accept = rot_in_valid && rot_in_ready;
    assign vec_accept = vec_in_valid && vec_in_ready;

    // Always ready to take outputs (for simplicity of demo)
    logic out_ready;
    assign out_ready = 1'b1;

    // Handshake: make a 1-entry "pending" request so we don't lose presses
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'b0;
        end else begin
            // queue a request on button press (ignore if already pending)
            if (start_pulse && !pending) begin
                pending <= 1'b1;
            end
            // clear when accepted by whichever mode is active
            if (!mode_vec) begin
                if (rot_accept) pending <= 1'b0;
            end else begin
                if (vec_accept) pending <= 1'b0;
            end
        end
    end

    logic signed [15:0] cosine, sine;
    cordic_rotator #(
        .XY_W(16),
        .ANGLE_W(32),
        .ITER(16),
        .GUARD(3),
        .GAIN_COMP(1)
    ) u_rot (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(rot_in_valid),
        .in_ready(rot_in_ready),
        .x_start(x_in_rot),
        .y_start(y_in_rot),
        .angle(angle_rot),
        .out_valid(rot_out_valid),
        .out_ready(out_ready),
        .cosine(cosine),
        .sine(sine)
    );

    logic signed [15:0] mag;
    logic signed [31:0] theta;
    cordic_vectoring #(
        .XY_W(16),
        .ANGLE_W(32),
        .ITER(16),
        .GUARD(3),
        .GAIN_COMP(1)
    ) u_vec (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(vec_in_valid),
        .in_ready(vec_in_ready),
        .x_start(x_in_vec),
        .y_start(y_in_vec),
        .out_valid(vec_out_valid),
        .out_ready(out_ready),
        .mag(mag),
        .theta(theta)
    );

    // Latch latest outputs for 7-seg display
    logic signed [15:0] cos_reg, sin_reg, mag_reg;
    logic signed [31:0] theta_reg;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cos_reg <= '0;
            sin_reg <= '0;
            mag_reg <= '0;
            theta_reg <= '0;
        end else begin
            if (rot_out_valid) begin
                cos_reg <= cosine;
                sin_reg <= sine;
            end
            if (vec_out_valid) begin
                mag_reg <= mag;
                theta_reg <= theta;
            end
        end
    end

    // Choose a 16-bit value to show (hex) on 7-seg + LEDs
    logic [15:0] disp_val;
    always_comb begin
        if (!mode_vec) begin
            disp_val = show_b ? sin_reg[15:0] : cos_reg[15:0];
        end else begin
            disp_val = show_b ? theta_reg[15:0] : mag_reg[15:0];
        end
    end

    // LEDs indicators
    always_comb begin
        led = disp_val;
        led[0] = mode_vec; // mode
        led[1] = show_b; // which output selected
        led[2] = pending; // queued request
        led[3] = rot_out_valid; // pulses when rotation result produced
        led[4] = vec_out_valid; // pulses when vectoring result produced
    end

    // 7-seg scan driver (active-low anodes and active-low segments on Basys3)
    // Using scan_cnt[15:14] gives ~381 Hz per digit (no flicker).
    logic [15:0] scan_cnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            scan_cnt <= '0;
        end else begin 
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    logic [1:0] digit_sel;
    assign digit_sel = scan_cnt[15:14];

    logic [3:0] nibble;
    always_comb begin
        case (digit_sel)
            2'd0: nibble = disp_val[3:0];
            2'd1: nibble = disp_val[7:4];
            2'd2: nibble = disp_val[11:8];
            default: nibble = disp_val[15:12];
        endcase
    end

    // active-low anodes: drive one low at a time
    always_comb begin
        an = 4'b1111;
        case (digit_sel)
            2'd0: an = 4'b1110; // AN0 active
            2'd1: an = 4'b1101; // AN1 active
            2'd2: an = 4'b1011; // AN2 active
            default: an = 4'b0111; // AN3 active
        endcase
    end

    // hex to 7-seg (seg[6:0] = {g,f,e,d,c,b,a} active-low)
    function automatic logic [6:0] hex7(input logic [3:0] x);
        case (x)
            4'h0: hex7 = 7'b1000000;
            4'h1: hex7 = 7'b1111001;
            4'h2: hex7 = 7'b0100100;
            4'h3: hex7 = 7'b0110000;
            4'h4: hex7 = 7'b0011001;
            4'h5: hex7 = 7'b0010010;
            4'h6: hex7 = 7'b0000010;
            4'h7: hex7 = 7'b1111000;
            4'h8: hex7 = 7'b0000000;
            4'h9: hex7 = 7'b0010000;
            4'hA: hex7 = 7'b0001000;
            4'hB: hex7 = 7'b0000011;
            4'hC: hex7 = 7'b1000110;
            4'hD: hex7 = 7'b0100001;
            4'hE: hex7 = 7'b0000110;
            default: hex7 = 7'b0001110; // F
        endcase
    endfunction

    always_comb begin
        seg = hex7(nibble);
        dp = 1'b1; // active-low DP
    end

endmodule

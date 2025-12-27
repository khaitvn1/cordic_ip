package cordic_pkg;
    localparam int XY_W = 16;
    localparam int ANGLE_W = 32;
    localparam int MAX_ITER = 32; // we are doing 16 in the current RTL, 32 is for future works
    
    localparam logic signed [31:0] ANG_PI = 32'sh8000_0000;
    localparam logic signed [31:0] ANG_PI_2 = 32'sh4000_0000;
  
    localparam logic signed [15:0] KINV_Q15 = 16'sd19898; // 0.6072529 * 2^15
    localparam int KINV_SHIFT = 15;

    localparam real PI = 3.14159265358979323846;

    function automatic logic signed [MAX_ITER-1:0] atan_lut(input int unsigned idx);
        case (idx)
          0: atan_lut = 32'sh2000_0000;
          1: atan_lut = 32'sh12E4_051D;
          2: atan_lut = 32'sh09FB_385B;
          3: atan_lut = 32'sh0511_11D4;
          4: atan_lut = 32'sh028B_0D43;
          5: atan_lut = 32'sh0145_77E1;
          6: atan_lut = 32'sh00A2_EC1E;
          7: atan_lut = 32'sh0051_F155;
          8: atan_lut = 32'sh0028_F953;
          9: atan_lut = 32'sh0014_7E6E;
          10: atan_lut = 32'sh000A_7CC8;
          11: atan_lut = 32'sh0005_3E64;
          12: atan_lut = 32'sh0002_9F32;
          13: atan_lut = 32'sh0001_4F99;
          14: atan_lut = 32'sh0000_A7CC;
          15: atan_lut = 32'sh0000_53E6;
          // add more in the future 16 ... 31
          default: atan_lut = 32'sd0;
        endcase
    endfunction

endpackage
package cordic_tb_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    typedef enum int {CORDIC_ROT=0, CORDIC_VEC=1} cordic_mode_e;
    typedef enum int {READY_ALWAYS=0, READY_RANDOM=1, READY_BURST=2} cordic_ready_mode_e;

    class cordic_cfg extends uvm_object;
        `uvm_object_utils(cordic_cfg)
        cordic_mode_e mode;
        bit gain_comp;
        int tol_xy_lsb;
        int tol_theta_lsb;
        cordic_ready_mode_e ready_mode;
        int unsigned ready_low_pct;
        int unsigned burst_start_pct;
        int unsigned burst_low_min;
        int unsigned burst_low_max;
        function new(string name="cordic_cfg"); 
            super.new(name);
        endfunction
    endclass : cordic_cfg

endpackage
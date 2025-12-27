module cordic_tb_top;

    timeunit 1ns;
    timeprecision 100ps;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import cordic_test_pkg::*;
    import cordic_seq_pkg::*;
    import cordic_agent_pkg::*;
    import cordic_env_pkg::*;

endmodule : cordic_tb_top

package cordic_agent_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import cordic_tb_pkg::*;
    import cordic_pkg::*;
    import cordic_seq_pkg::*;
    `include "cordic_monitor.sv"
    `include "cordic_driver.sv"
    `include "cordic_sequencer.sv"
    `include "cordic_agent.sv"
endpackage : cordic_agent_pkg
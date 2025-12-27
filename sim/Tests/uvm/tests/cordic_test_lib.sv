import uvm_pkg::*;
`include "uvm_macros.svh"
import cordic_tb_pkg::*;
import cordic_seq_pkg::*;
import cordic_env_pkg::*;

// placeholder
class simple_cordic_test extends base_cordic_test;
    `uvm_component_utils(simple_cordic_test)

    function new(string name="simple_cordic_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    uvm_config_db#(uvm_object_wrapper)::set(this, "env.agt.seqr.run_phase", "default_sequence", simple_cordic_seq::type_id::get());
    endfunction
endclass

class all_cordic_test extends base_cordic_test;
    `uvm_component_utils(all_cordic_test)

    cordic_cfg cfg;

    function new(string name="all_cordic_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(cordic_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "Missing cordic_cfg in all_cordic_test")
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this, "all_cordic_test start");

        if (cfg.mode == CORDIC_ROT) begin
            rot_directed_seq s_dir;
            rot_random_seq   s_rnd;

            s_dir = rot_directed_seq::type_id::create("s_dir");
            s_rnd = rot_random_seq::type_id::create("s_rnd");

            s_dir.start(env.agt.seqr);

            s_rnd.n_items = 500;
            s_rnd.start(env.agt.seqr);
        end else begin // CORDIC_VEC
            vec_directed_seq s_dir;
            vec_random_seq   s_rnd;

            s_dir = vec_directed_seq::type_id::create("s_dir");
            s_rnd = vec_random_seq::type_id::create("s_rnd");

            s_dir.start(env.agt.seqr);

            s_rnd.n_items = 500;
            s_rnd.start(env.agt.seqr);
        end
        phase.drop_objection(this, "all_cordic_test done");
    endtask
endclass
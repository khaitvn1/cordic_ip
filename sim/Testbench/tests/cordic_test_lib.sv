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

        if (!uvm_config_db#(cordic_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "Missing cordic_cfg in all_cordic_test")
        end
    endfunction

    task run_phase(uvm_phase phase);
        rot_directed_seq s_dir;
        rot_random_seq s_rnd;
        vec_directed_seq v_dir;
        vec_random_seq v_rnd;
        cordic_backpressure_seq bp_seq;

        super.run_phase(phase);
        phase.raise_objection(this, "all_cordic_test start");

        if (cfg.mode == CORDIC_ROT) begin
            s_dir = rot_directed_seq::type_id::create("s_dir");
            s_rnd = rot_random_seq::type_id::create("s_rnd");
            s_dir.start(env.agt.seqr);
            s_rnd.n_items = 500;
            s_rnd.start(env.agt.seqr);
        end else begin
            v_dir = vec_directed_seq::type_id::create("v_dir");
            v_rnd = vec_random_seq::type_id::create("v_rnd");
            v_dir.start(env.agt.seqr);
            v_rnd.n_items = 500;
            v_rnd.start(env.agt.seqr);
        end

        bp_seq = cordic_backpressure_seq::type_id::create("bp_seq");
        bp_seq.n_items = 100;
        bp.ready_mode = READY_RANDOM;
        bp_seq.start(env.agt.seqr);

        phase.drop_objection(this, "all_cordic_test done");
    endtask
endclass
class base_cordic_test extends uvm_test;
    `uvm_component_utils(base_cordic_test)

    cordic_env env;

    function new(string name = "base_cordic_test", uvm_component parent);
        super.new(name,parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_int::set(this, "*", "recording_detail", UVM_FULL);
        env = cordic_env::type_id::create("env", this);
    endfunction : build_phase

    // Run phase
    virtual task run_phase(uvm_phase phase);
        uvm_objection obj = phase.get_objection();
        obj.set_drain_time(this, 2000ns);
    endtask : run_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), {"Start of simulation for ", get_full_name()}, UVM_HIGH);
    endfunction : start_of_simulation_phase

    virtual function void check_phase(uvm_phase phase);
        check_config_usage();
    endfunction : check_phase
endclass : base_cordic_test
class cordic_env extends uvm_env;
    `uvm_component_utils(cordic_env)

    cordic_agent agt;
    cordic_sb sb;

    function new(string name = "cordic_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = cordic_agent::type_id::create("agt", this);
        sb = cordic_sb::type_id::create("sb", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.item_collect_port.connect(sb.item_collect_export); 
    endfunction : connect_phase

endclass : cordic_env
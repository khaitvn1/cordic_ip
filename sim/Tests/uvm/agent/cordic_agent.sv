class cordic_agent extends uvm_agent;
    `uvm_component_utils(cordic_agent)

    cordic_driver drv;
    cordic_monitor mon;
    cordic_sequencer seqr;

    function new(string name = "cordic_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            drv  = cordic_driver::type_id::create("drv", this);
            seqr = cordic_sequencer::type_id::create("seqr", this);
        end
        mon = cordic_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass
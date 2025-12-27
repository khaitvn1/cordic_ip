class base_cordic_seq extends uvm_sequence #(cordic_seq_item);
    `uvm_object_utils(base_cordic_seq)

    function new(string name = "base_cordic_seq");
        super.new(name);
    endfunction : new

    virtual task pre_body();
        uvm_phase phase;
        `ifdef UVM_VERSION_1_2
            phase = get_starting_phase();
        `else
            phase = starting_phase;
        `endif
        if (phase != null) begin
            phase.raise_objection(this, get_type_name());
            `uvm_info(get_type_name(), "Raise Objection", UVM_MEDIUM)
        end
    endtask : pre_body

    virtual task body();
        `uvm_fatal(get_type_name(), "base_cordic_seq.body() called directly; extend and override in a child sequence")
    endtask : body

    virtual task post_body();
        uvm_phase phase;
        `ifdef UVM_VERSION_1_2
            phase = get_starting_phase();
        `else
            phase = starting_phase;
        `endif
        if (phase != null) begin
            phase.drop_objection(this, get_type_name());
            `uvm_info(get_type_name(), "Drop Objection", UVM_MEDIUM)
        end
    endtask : post_body
endclass : base_cordic_seq
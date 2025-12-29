class cordic_sequencer extends uvm_sequencer #(cordic_seq_item);
    `uvm_component_utils(cordic_sequencer)

    function new (string name = "cordic_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : cordic_sequencer
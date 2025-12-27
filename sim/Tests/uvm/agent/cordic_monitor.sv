class cordic_monitor extends uvm_monitor;
    `uvm_component_utils(cordic_monitor)

    virtual cordic_if.mon vif;

    uvm_analysis_port#(cordic_seq_item) item_collect_port;
    cordic_seq_item in_queue[$];

    function new(string name = "cordic_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collect_port = new("item_collect_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual cordic_if.mon)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "vif not found")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        cordic_seq_item tr;
        super.run_phase(phase);
        do @(vif.mon_cb); while (vif.mon_cb.rst_n !== 1'b1);

        forever begin
            @(vif.mon_cb);
 
            // if reset asserted, clear input queue
            if (vif.mon_cb.rst_n === 1'b0) begin
                in_queue.delete();
                continue;
            end

            // capture inputs when valid
            if (vif.mon_cb.in_valid && vif.mon_cb.in_ready) begin
                tr = cordic_seq_item::type_id::create("tr", this);
                tr.x_in = vif.mon_cb.x_in;
                tr.y_in = vif.mon_cb.y_in;
                tr.z_in = vif.mon_cb.z_in;
                in_queue.push_back(tr);
            end

            // capture outputs when ready and pair with oldest input
            if (vif.mon_cb.out_valid && vif.mon_cb.out_ready) begin
                if (in_queue.size() == 0) begin
                    `uvm_fatal(get_type_name(), "Output received with no matching input in queue")
                end else begin
                    tr = in_queue.pop_front();
                    tr.cos_out = vif.mon_cb.cos_out;
                    tr.sin_out = vif.mon_cb.sin_out;
                    tr.mag_out = vif.mon_cb.mag_out;
                    tr.theta_out = vif.mon_cb.theta_out;

                    item_collect_port.write(tr);
                end
            end
        end
    endtask : run_phase

endclass : cordic_monitor
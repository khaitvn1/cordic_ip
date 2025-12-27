class cordic_driver extends uvm_driver #(cordic_seq_item);
    `uvm_component_utils(cordic_driver)

    virtual cordic_if.drv drv_vif; // for driving
    virtual cordic_if.mon mon_vif; // for sampling rst_n (had problem with that earlier via modport drv in interface)

    function new(string name="cordic_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual cordic_if.drv)::get(this, "", "vif", drv_vif))
            `uvm_fatal(get_type_name(), "drv_vif not set")

        if (!uvm_config_db#(virtual cordic_if.mon)::get(this, "", "mon_vif", mon_vif))
            `uvm_fatal(get_type_name(), "mon_vif not set")
    endfunction

    task run_phase(uvm_phase phase);
        cordic_seq_item tr;
        super.run_phase(phase);

        drv_vif.drv_cb.in_valid  <= 1'b0;
        drv_vif.drv_cb.x_in <= '0;
        drv_vif.drv_cb.y_in <= '0;
        drv_vif.drv_cb.z_in <= '0;
        drv_vif.drv_cb.out_ready <= 1'b1;

        // wait reset release via monitor clocking block
        do @(mon_vif.mon_cb); while (mon_vif.mon_cb.rst_n !== 1'b1);

        forever begin
            seq_item_port.get_next_item(tr);
            drv_vif.drv_cb.x_in <= tr.x_in;
            drv_vif.drv_cb.y_in <= tr.y_in;
            drv_vif.drv_cb.z_in <= tr.z_in;
            drv_vif.drv_cb.in_valid <= 1'b1;

            do @(drv_vif.drv_cb); while (!(drv_vif.drv_cb.in_ready));

            drv_vif.drv_cb.in_valid <= 1'b0;

            seq_item_port.item_done();
        end
    endtask
endclass
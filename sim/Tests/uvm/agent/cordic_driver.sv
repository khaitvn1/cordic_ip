class cordic_driver extends uvm_driver #(cordic_seq_item);
    `uvm_component_utils(cordic_driver)

    virtual cordic_if.drv vif;

    function new(string name="cordic_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual cordic_if.drv)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "vif not set (expected virtual cordic_if.drv)")
        end
    endfunction

    task automatic drive(cordic_seq_item tr);
        vif.drv_cb.x_in <= tr.x_in;
        vif.drv_cb.y_in <= tr.y_in;
        vif.drv_cb.z_in <= tr.z_in;
        vif.drv_cb.in_valid <= 1'b1;

        // Wait for accept
        forever begin
            @(vif.drv_cb);

            // If reset asserted, abort
            if (vif.drv_cb.rst_n !== 1'b1) begin
                vif.drv_cb.in_valid <= 1'b0;
                return;
            end

            if (vif.drv_cb.in_ready) break;
        end

        // Deassert valid next cycle
        vif.drv_cb.in_valid <= 1'b0;
    endtask

    task run_phase(uvm_phase phase);
        cordic_seq_item tr;
        vif.drv_cb.in_valid <= 1'b0;
        vif.drv_cb.x_in <= '0;
        vif.drv_cb.y_in <= '0;
        vif.drv_cb.z_in <= '0;
        vif.drv_cb.out_ready <= 1'b1;
        do @(vif.drv_cb); while (vif.drv_cb.rst_n !== 1'b1);

        forever begin
            seq_item_port.get_next_item(tr);

            if (vif.drv_cb.rst_n !== 1'b1) begin
                do @(vif.drv_cb); while (vif.drv_cb.rst_n !== 1'b1);
            end

            drive(tr);
            seq_item_port.item_done();
        end
    endtask
endclass
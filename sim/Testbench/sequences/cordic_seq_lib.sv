class rot_directed_seq extends base_cordic_seq;
    `uvm_object_utils(rot_directed_seq)

    function new(string name="rot_directed_seq");
        super.new(name);
    endfunction

    virtual task body();
        cordic_seq_item req;

        `uvm_info(get_type_name(), "Running rot_directed_seq", UVM_LOW)

        // 0 deg
        req = cordic_seq_item::type_id::create("req0");
        start_item(req);
            req.x_in = 16'sd20000;
            req.y_in = 16'sd0;
            req.z_in = 32'h0000_0000;
        finish_item(req);

        // +45 deg (pi/4)
        req = cordic_seq_item::type_id::create("req1");
        start_item(req);
            req.x_in = 16'sd20000;
            req.y_in = 16'sd0;
            req.z_in = 32'h2000_0000;
        finish_item(req);

        // +90 deg (pi/2)
        req = cordic_seq_item::type_id::create("req2");
        start_item(req);
            req.x_in = 16'sd20000;
            req.y_in = 16'sd0;
            req.z_in = 32'h4000_0000;
        finish_item(req);

        // 180 deg (pi)
        req = cordic_seq_item::type_id::create("req3");
        start_item(req);
            req.x_in = 16'sd20000;
            req.y_in = 16'sd0;
            req.z_in = 32'h8000_0000;
        finish_item(req);

        // -45 deg
        req = cordic_seq_item::type_id::create("req4");
        start_item(req);
            req.x_in = 16'sd20000;
            req.y_in = 16'sd0;
            req.z_in = 32'hE000_0000;
        finish_item(req);

        // non-axis vector, +30 deg
        req = cordic_seq_item::type_id::create("req5");
        start_item(req);
            req.x_in = 16'sd12000;
            req.y_in = -16'sd7000;
            req.z_in = 32'h1555_5555;
        finish_item(req);

  endtask
endclass

class rot_random_seq extends base_cordic_seq;
    `uvm_object_utils(rot_random_seq)

    rand int unsigned n_items;
    constraint c_n_items { n_items inside {[50:200]}; }

    function new(string name="rot_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        cordic_seq_item req;
        cordic_cfg cfg;
        int i;

        `uvm_info(get_type_name(), "Running rot_random_seq", UVM_LOW)

        if (!uvm_config_db#(cordic_cfg)::get(null, "*", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "rot_random_seq: missing cfg")
        end

        for (i = 0; i < n_items; i++) begin
            req = cordic_seq_item::type_id::create($sformatf("req_r%0d", i));
            start_item(req);

            if (cfg.gain_comp) begin
                if (!req.randomize() with {
                    x_in inside {[-30000:30000]};
                    y_in inside {[-30000:30000]};
                    !(x_in == 0 && y_in == 0);
                    z_in inside { [32'h0000_0000 : 32'h7FFF_FFFF],
                                [32'h8000_0000 : 32'hFFFF_FFFF] };
                }) `uvm_fatal(get_type_name(), "ROT randomize failed (gain_comp=1)")
            end else begin
                if (!req.randomize() with {
                    x_in inside {[-20000:20000]};
                    y_in inside {[-20000:20000]};
                    !(x_in == 0 && y_in == 0);
                    z_in inside { [32'h0000_0000 : 32'h7FFF_FFFF],
                                [32'h8000_0000 : 32'hFFFF_FFFF] };
                }) `uvm_fatal(get_type_name(), "ROT randomize failed (gain_comp=0)")
            end

            finish_item(req);
        end
    endtask
endclass

class vec_directed_seq extends base_cordic_seq;
    `uvm_object_utils(vec_directed_seq)

    function new(string name="vec_directed_seq");
        super.new(name);
    endfunction

    virtual task body();
        cordic_seq_item req;

        `uvm_info(get_type_name(), "Running vec_directed_seq", UVM_LOW)

        // (1,0)
        req = cordic_seq_item::type_id::create("v0");
        start_item(req);
        req.x_in = 16'sd20000;
        req.y_in = 16'sd0;
        req.z_in = 32'h0;
        finish_item(req);

        // (0,1)
        req = cordic_seq_item::type_id::create("v1");
        start_item(req);
        req.x_in = 16'sd0;
        req.y_in = 16'sd20000;
        req.z_in = 32'h0;
        finish_item(req);

        // (-1,0)
        req = cordic_seq_item::type_id::create("v2");
        start_item(req);
        req.x_in = -16'sd20000;
        req.y_in = 16'sd0;
        req.z_in = 32'h0;
        finish_item(req);

        // (0,-1)
        req = cordic_seq_item::type_id::create("v3");
        start_item(req);
        req.x_in = 16'sd0;
        req.y_in = -16'sd20000;
        req.z_in = 32'h0;
        finish_item(req);

        // Q1
        req = cordic_seq_item::type_id::create("v4");
        start_item(req);
        req.x_in = 16'sd12000;
        req.y_in = 16'sd9000;
        req.z_in = 32'h0;
        finish_item(req);

        // Q3
        req = cordic_seq_item::type_id::create("v5");
        start_item(req);
        req.x_in = -16'sd12000;
        req.y_in = -16'sd9000;
        req.z_in = 32'h0;
        finish_item(req);

    endtask
endclass

class vec_random_seq extends base_cordic_seq;
    `uvm_object_utils(vec_random_seq)

    rand int unsigned n_items;
    constraint c_n_items { n_items inside {[50:200]}; }

    function new(string name="vec_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        cordic_seq_item req;
        int i;

        `uvm_info(get_type_name(), "Running vec_random_seq", UVM_LOW)

        for (i = 0; i < n_items; i++) begin
            req = cordic_seq_item::type_id::create($sformatf("req_v%0d", i));
            start_item(req);

            assert(req.randomize() with {
                x_in inside {[-25000:25000]};
                y_in inside {[-25000:25000]};
                !(x_in == 0 && y_in == 0);
                z_in == 32'h0; // ignored for vectoring mode
            });

            finish_item(req);
        end
    endtask
endclass

class cordic_backpressure_seq extends base_cordic_seq;
    `uvm_object_utils(cordic_backpressure_seq)

    int unsigned n_items = 50;

    cordic_ready_mode_e ready_mode = READY_BURST;
    int unsigned ready_low_pct = 25;
    int unsigned burst_start_pct = 10;
    int unsigned burst_low_min = 3;
    int unsigned burst_low_max = 12;

    cordic_cfg cfg;

    function new(string name="cordic_backpressure_seq");
        super.new(name);
    endfunction

    task body();
        cordic_seq_item req;

        if (!uvm_config_db#(cordic_cfg)::get(null, "*", "cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "cordic_backpressure_seq: missing cfg")
        end

        cfg.ready_mode = ready_mode;
        cfg.ready_low_pct = ready_low_pct;
        cfg.burst_start_pct = burst_start_pct;
        cfg.burst_low_min = burst_low_min;
        cfg.burst_low_max = burst_low_max;

        `uvm_info(get_type_name(), $sformatf("Running cordic_backpressure_seq: n_items=%0d, ready_mode=%0d, low_pct=%0d, burst_start=%0d burst=[%0d..%0d]",
            n_items, ready_mode, ready_low_pct, burst_start_pct, burst_low_min, burst_low_max), UVM_LOW)

        for (int i = 0; i < n_items; i++) begin
            req = cordic_seq_item::type_id::create($sformatf("req_bp%0d", i));
            start_item(req);

            if (cfg.mode == CORDIC_ROT) begin
                if (!req.randomize() with {
                    x_in inside {[-20000:20000]};
                    y_in inside {[-20000:20000]};
                    !(x_in == 0 && y_in == 0);
                    z_in inside { [32'h0000_0000 : 32'h7FFF_FFFF],
                                    [32'h8000_0000 : 32'hFFFF_FFFF] };
                    }) `uvm_fatal(get_type_name(), "ROT randomize failed")
            end else begin // CORDIC_VEC
                if (!req.randomize() with {
                    x_in inside {[-20000:20000]};
                    y_in inside {[-20000:20000]};
                    !(x_in == 0 && y_in == 0);
                    z_in == 32'h0; // ignored for vectoring mode
                }) `uvm_fatal(get_type_name(), "VEC randomize failed")
            end

            finish_item(req);
        end
    endtask
endclass

// placeholder
class simple_cordic_seq extends rot_directed_seq;
    `uvm_object_utils(simple_cordic_seq)
  
    function new(string name="simple_cordic_seq"); 
        super.new(name);
    endfunction
endclass

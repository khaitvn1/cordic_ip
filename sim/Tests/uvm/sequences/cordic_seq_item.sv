class cordic_seq_item extends uvm_sequence_item;
    `uvm_object_utils(cordic_seq_item)
    // Stimulus 
    rand logic signed [cordic_pkg::XY_W-1:0] x_in;
    rand logic signed [cordic_pkg::XY_W-1:0] y_in;
    rand logic signed [cordic_pkg::ANGLE_W-1:0] z_in;

    // Outputs from DUT
    logic [cordic_pkg::XY_W-1:0] cos_out;
    logic [cordic_pkg::XY_W-1:0] sin_out;
    logic [cordic_pkg::XY_W-1:0] mag_out;
    logic [cordic_pkg::ANGLE_W-1:0] theta_out;

    function new(string name = "cordic_seq_item");
        super.new(name);
    endfunction

endclass : cordic_seq_item
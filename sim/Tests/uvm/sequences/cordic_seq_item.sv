import uvm_pkg::*;
import cordic_tb_pkg::*;
import cordic_pkg::*;

class cordic_seq_item extends uvm_sequence_item;
    `uvm_object_utils(cordic_seq_item)

    rand logic signed [15:0] x_in;
    rand logic signed [15:0] y_in;
    rand logic signed [31:0] z_in;

    logic [15:0] cos_out;
    logic [15:0] sin_out;
    logic [15:0] mag_out;
    logic [31:0] theta_out;

    function new(string name = "cordic_seq_item");
        super.new(name);
    endfunction

endclass : cordic_seq_item
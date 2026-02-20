// tb/uvm/cpu_pkg.sv
// UVM package: transactions, configuration, factory registration

`timescale 1ns / 1ps
package cpu_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Transaction class: represents a single instruction diagnostic or mem op (basic)
  class cpu_trans extends uvm_sequence_item;
    rand bit [31:0] instr;
    rand int unsigned pc;

    `uvm_object_utils(cpu_trans)

    function new(string name = "cpu_trans");
      super.new(name);
    endfunction
  endclass

  // Config class for testbench parameters
  class cpu_env_cfg;
    bit [31:0] seed;
    int unsigned max_cycles;
    function new();
      seed = 32'hdeadbeef;
      max_cycles = 256;
    endfunction
  endclass

endpackage : cpu_pkg


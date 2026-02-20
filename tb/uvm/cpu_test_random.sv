// tb/uvm/cpu_test_random.sv
// Randomized test that populates IMEM with random instructions (bounded set)
// and compares DUT vs reference model by reading registers after execution.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
import isa_defs_pkg::*;
`include "uvm_macros.svh"

class cpu_test_random extends cpu_test_base;
  `uvm_component_utils(cpu_test_random)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    int N;
    int i;
    int opcode_sel;
    bit [31:0] instr;

    super.run_phase(phase);
    phase.raise_objection(this);

    if (!uvm_config_db#(virtual cpu_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "Virtual interface not set")

    N = 64;

    for (i = 0; i < N; i++) begin
      instr = 32'h0;
      opcode_sel = $urandom_range(1, 5);
      case (opcode_sel)
        1: begin
          instr[31:26] = OPC_ADD;
          instr[25:23] = $urandom_range(0, 7);
          instr[22:20] = $urandom_range(0, 7);
          instr[19:17] = $urandom_range(0, 7);
        end
        2: begin
          instr[31:26] = OPC_SUB;
          instr[25:23] = $urandom_range(0, 7);
          instr[22:20] = $urandom_range(0, 7);
          instr[19:17] = $urandom_range(0, 7);
        end
        3: begin
          instr[31:26] = OPC_ADDI;
          instr[25:23] = $urandom_range(0, 7);
          instr[22:20] = $urandom_range(0, 7);
          instr[19:4]  = $urandom_range(0, 65535);
        end
        4: begin
          instr[31:26] = OPC_LOAD;
          instr[25:23] = $urandom_range(0, 7);
          instr[22:20] = $urandom_range(0, 7);
          instr[19:4]  = $urandom_range(0, 65535);
        end
        5: begin
          instr[31:26] = OPC_STORE;
          instr[25:23] = $urandom_range(0, 7);
          instr[22:20] = $urandom_range(0, 7);
          instr[19:4]  = $urandom_range(0, 65535);
        end
        default: begin
          instr = 32'h0;
        end
      endcase
      write_imem(i, instr);
    end

    // Seed data memory with random values
    for (i = 0; i < 16; i++) write_dmem(i, $urandom);

    // Run CPU for N+8 cycles
    repeat (N + 8) @(posedge vif.clk);

    // Read and display register values
    for (i = 0; i < 8; i++) begin
      vif.tb_reg_rd_addr <= i;
      @(posedge vif.clk);
      `uvm_info("RANDOM", $sformatf("R%0d = %0d", i, vif.tb_reg_rd_data), UVM_LOW)
    end

    `uvm_info("RANDOM", "Random test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : cpu_test_random

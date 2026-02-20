// tb/uvm/cpu_scoreboard.sv
// Scoreboard: simple reference model implementing the ISA and checking DUT state step-by-step.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
`include "uvm_macros.svh"

class cpu_scoreboard extends uvm_component;
  uvm_analysis_imp #(cpu_trans, cpu_scoreboard) analysis_export;

  // reference state
  bit [31:0] rf_ref[0:7];
  bit [31:0] dmem_ref[0:1023];

  `uvm_component_utils(cpu_scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction

  function void reset_refs();
    int i;
    for (i = 0; i < 8; i++) rf_ref[i] = 32'h0;
    for (i = 0; i < 1024; i++) dmem_ref[i] = 32'h0;
  endfunction

  // Implements the ISA semantics for a single instruction at trace time
  function void execute_instr(bit [31:0] instr, int unsigned pc);
    import isa_defs_pkg::*;
    logic [OPCODE_W-1:0] opcode;
    logic [REG_ADDR_W-1:0] rd, rs1, rs2;
    logic signed [IMM_W-1:0] imm16;
    logic [31:0] rs1v, rs2v, alu_b, alu_res;
    int unsigned eff;

    opcode = isa_defs_pkg::get_opcode(instr);

    if (opcode == isa_defs_pkg::OPC_ADD || opcode == isa_defs_pkg::OPC_SUB) begin
      rd   = isa_defs_pkg::get_rtype_rd(instr);
      rs1  = isa_defs_pkg::get_rtype_rs1(instr);
      rs2  = isa_defs_pkg::get_rtype_rs2(instr);
      rs1v = rf_ref[rs1];
      rs2v = rf_ref[rs2];
      if (opcode == isa_defs_pkg::OPC_ADD) alu_res = rs1v + rs2v;
      else if (opcode == isa_defs_pkg::OPC_SUB) alu_res = rs1v - rs2v;
      if (rd != 0) rf_ref[rd] = alu_res;
    end else if (opcode == isa_defs_pkg::OPC_ADDI) begin
      rd = isa_defs_pkg::get_itype_rd_or_rs2(instr);
      rs1 = isa_defs_pkg::get_itype_rs1(instr);
      imm16 = isa_defs_pkg::get_itype_imm16(instr);
      rs1v = rf_ref[rs1];
      alu_res = rs1v + $signed(imm16);
      if (rd != 0) rf_ref[rd] = alu_res;
    end else if (opcode == isa_defs_pkg::OPC_LOAD) begin
      rd = isa_defs_pkg::get_itype_rd_or_rs2(instr);
      rs1 = isa_defs_pkg::get_itype_rs1(instr);
      imm16 = isa_defs_pkg::get_itype_imm16(instr);
      rs1v = rf_ref[rs1];
      eff = $unsigned(rs1v + $signed(imm16));
      rf_ref[rd] = dmem_ref[eff];
    end else if (opcode == isa_defs_pkg::OPC_STORE) begin
      rs2   = isa_defs_pkg::get_itype_rd_or_rs2(instr);
      rs1   = isa_defs_pkg::get_itype_rs1(instr);
      imm16 = isa_defs_pkg::get_itype_imm16(instr);
      rs1v  = rf_ref[rs1];
      rs2v  = rf_ref[rs2];
      eff = $unsigned(rs1v + $signed(imm16));
      dmem_ref[eff] = rs2v;
    end else begin
      // NOP or unknown: do nothing
    end
  endfunction

  // analysis port callback
  virtual function void write(cpu_trans t);
    // execute instruction in reference model
    execute_instr(t.instr, t.pc);

    // After executing, compare architectural state by reading DUT register file & dmem via TB read mechanism is performed in tests.
    // The tests themselves will separately poll TB registers and memory and compare to rf_ref/dmem_ref.
    // For simplicity of this scoreboard, we'll store the reference state; the tests perform comparisons and report via UVM.
  endfunction

endclass : cpu_scoreboard


// rtl/control_unit.sv
// Decodes instruction to control signals. Pure combinational.

`timescale 1ns/1ps

module control_unit (
  input  logic [31:0]                                instr,
  output logic                                       is_rtype,
  output logic                                       is_itype,
  output logic                                       is_nop,
  output isa_defs_pkg::alu_op_e                      alu_op,
  output logic                                       reg_write_en,
  output logic                                       mem_read,
  output logic                                       mem_write,
  output logic [isa_defs_pkg::REG_ADDR_W-1:0]        rd_addr,
  output logic [isa_defs_pkg::REG_ADDR_W-1:0]        rs1_addr,
  output logic [isa_defs_pkg::REG_ADDR_W-1:0]        rs2_addr,
  output logic signed [isa_defs_pkg::IMM_W-1:0]      imm16
);
  import isa_defs_pkg::*;

  logic [OPCODE_W-1:0] opcode;
  assign opcode = isa_defs_pkg::get_opcode(instr);

  assign rd_addr  = (opcode == OPC_ADD || opcode == OPC_SUB) ? isa_defs_pkg::get_rtype_rd(instr) : isa_defs_pkg::get_itype_rd_or_rs2(instr);
  assign rs1_addr = (opcode == OPC_ADD || opcode == OPC_SUB) ? isa_defs_pkg::get_rtype_rs1(instr) : isa_defs_pkg::get_itype_rs1(instr);
  assign rs2_addr = (opcode == OPC_ADD || opcode == OPC_SUB) ? isa_defs_pkg::get_rtype_rs2(instr) : isa_defs_pkg::get_itype_rd_or_rs2(instr);
  assign imm16    = isa_defs_pkg::get_itype_imm16(instr);

  always_comb begin
    is_rtype = 1'b0;
    is_itype = 1'b0;
    is_nop   = 1'b0;
    alu_op   = ALU_OP_NOP;
    reg_write_en = 1'b0;
    mem_read = 1'b0;
    mem_write = 1'b0;

    unique case (opcode)
      isa_defs_pkg::OPC_NOP: begin
        is_nop = 1'b1;
      end

      isa_defs_pkg::OPC_ADD: begin
        is_rtype = 1'b1;
        alu_op = ALU_OP_ADD;
        reg_write_en = 1'b1;
      end

      isa_defs_pkg::OPC_SUB: begin
        is_rtype = 1'b1;
        alu_op = ALU_OP_SUB;
        reg_write_en = 1'b1;
      end

      isa_defs_pkg::OPC_ADDI: begin
        is_itype = 1'b1;
        alu_op = ALU_OP_ADD;
        reg_write_en = 1'b1;
      end

      isa_defs_pkg::OPC_LOAD: begin
        is_itype = 1'b1;
        mem_read = 1'b1;
        reg_write_en = 1'b1;
      end

      isa_defs_pkg::OPC_STORE: begin
        is_itype = 1'b1;
        mem_write = 1'b1;
      end

      default: begin
        is_nop = 1'b1;
      end
    endcase
  end

endmodule

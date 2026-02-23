// rtl/isa_defs_pkg.sv
// Package: ISA definitions, opcodes, field extraction helpers

`timescale 1ns / 1ps
package isa_defs_pkg;
  localparam int OPCODE_W = 6;

  // Register address width and count
  localparam int REG_ADDR_W = 3;
  localparam int REG_COUNT = 1 << REG_ADDR_W;

  // Immediate width for I-type
  localparam int IMM_W = 16;

  // Opcodes (6-bit)
  localparam logic [OPCODE_W-1:0] OPC_NOP   = 6'b000000;
  localparam logic [OPCODE_W-1:0] OPC_ADD   = 6'b000001; // R-type
  localparam logic [OPCODE_W-1:0] OPC_SUB   = 6'b000010; // R-type
  localparam logic [OPCODE_W-1:0] OPC_ADDI  = 6'b000011; // I-type
  localparam logic [OPCODE_W-1:0] OPC_LOAD  = 6'b000100; // I-type
  localparam logic [OPCODE_W-1:0] OPC_STORE = 6'b000101; // I-type

  // ALU operations enumerated
  typedef enum logic [2:0] {
    ALU_OP_NOP  = 3'd0,
    ALU_OP_ADD  = 3'd1,
    ALU_OP_SUB  = 3'd2
  } alu_op_e;

  // Instruction bit positions (inclusive)
  // Common:
  localparam int INS_OPCODE_MSB = 31;
  localparam int INS_OPCODE_LSB = 26;

  // R-type fields
  localparam int INS_R_RD_MSB = 25;
  localparam int INS_R_RD_LSB = 23;
  localparam int INS_R_RS1_MSB = 22;
  localparam int INS_R_RS1_LSB = 20;
  localparam int INS_R_RS2_MSB = 19;
  localparam int INS_R_RS2_LSB = 17;

  // I-type fields
  localparam int INS_I_RD_RS2_MSB = 25; // rd (ADDI/LOAD) or rs2 (STORE)
  localparam int INS_I_RD_RS2_LSB = 23;
  localparam int INS_I_RS1_MSB = 22;
  localparam int INS_I_RS1_LSB = 20;
  localparam int INS_I_IMM_MSB = 19;
  localparam int INS_I_IMM_LSB = 4;

  // Field extraction functions — each uses only a bit-slice of instr
  /* verilator lint_off UNUSEDSIGNAL */
  function automatic logic [OPCODE_W-1:0] get_opcode(logic [31:0] instr);
    get_opcode = instr[INS_OPCODE_MSB:INS_OPCODE_LSB];
  endfunction

  function automatic logic [REG_ADDR_W-1:0] get_rtype_rd(logic [31:0] instr);
    get_rtype_rd = instr[INS_R_RD_MSB:INS_R_RD_LSB];
  endfunction

  function automatic logic [REG_ADDR_W-1:0] get_rtype_rs1(logic [31:0] instr);
    get_rtype_rs1 = instr[INS_R_RS1_MSB:INS_R_RS1_LSB];
  endfunction

  function automatic logic [REG_ADDR_W-1:0] get_rtype_rs2(logic [31:0] instr);
    get_rtype_rs2 = instr[INS_R_RS2_MSB:INS_R_RS2_LSB];
  endfunction

  function automatic logic [REG_ADDR_W-1:0] get_itype_rd_or_rs2(logic [31:0] instr);
    get_itype_rd_or_rs2 = instr[INS_I_RD_RS2_MSB:INS_I_RD_RS2_LSB];
  endfunction

  function automatic logic [REG_ADDR_W-1:0] get_itype_rs1(logic [31:0] instr);
    get_itype_rs1 = instr[INS_I_RS1_MSB:INS_I_RS1_LSB];
  endfunction

  function automatic logic signed [IMM_W-1:0] get_itype_imm16(logic [31:0] instr);
    get_itype_imm16 = instr[INS_I_IMM_MSB:INS_I_IMM_LSB];
  endfunction
  /* verilator lint_on UNUSEDSIGNAL */

endpackage : isa_defs_pkg

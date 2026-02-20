// rtl/alu.sv
// Simple ALU: supports ADD, SUB, NOP
// Combinational operation based on alu_op

`timescale 1ns/1ps

module alu (
  input  logic [31:0]              a,
  input  logic [31:0]              b,
  input  isa_defs_pkg::alu_op_e    op,
  output logic [31:0]              result
);
  import isa_defs_pkg::*;

  always_comb begin
    case (op)
      ALU_OP_ADD: result = a + b;
      ALU_OP_SUB: result = a - b;
      default:    result = 32'h00000000;
    endcase
  end

endmodule

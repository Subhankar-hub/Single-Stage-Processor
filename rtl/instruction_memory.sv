// rtl/instruction_memory.sv
// Simple instruction memory (behavioral) with TB load port.
// Word-addressed memory: address index selects 32-bit word.

`timescale 1ns/1ps

module instruction_memory #(
  parameter int DEPTH = 1024
)(
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic [31:0]              addr_word,
  output logic [31:0]              instr_out,
  input  logic                     tb_we,
  input  logic [$clog2(DEPTH)-1:0] tb_addr,
  input  logic [31:0]              tb_wdata
);

  logic [31:0] mem [0:DEPTH-1];

  initial begin
    `ifdef SIM_PROGRAM_HEX
      $readmemh("sim/program.hex", mem);
    `endif
  end

  always_comb begin
    if (addr_word < DEPTH)
      instr_out = mem[addr_word];
    else
      instr_out = 32'h00000000;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // keep contents unchanged on reset
    end else begin
      if (tb_we) begin
        mem[tb_addr] <= tb_wdata;
      end
    end
  end

endmodule

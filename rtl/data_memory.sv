// rtl/data_memory.sv
// Data memory: synchronous write, combinational read. Word-addressed.

`timescale 1ns/1ps

module data_memory #(
  parameter int DEPTH = 1024
)(
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     cpu_we,
  input  logic [$clog2(DEPTH)-1:0] cpu_addr,
  input  logic [31:0]              cpu_wdata,
  output logic [31:0]              cpu_rdata,
  input  logic                     tb_we,
  input  logic [$clog2(DEPTH)-1:0] tb_addr,
  input  logic [31:0]              tb_wdata,
  input  logic                     tb_re,
  output logic [31:0]              tb_rdata
);

  logic [31:0] mem [0:DEPTH-1];

  always_comb begin
    if (cpu_addr < DEPTH)
      cpu_rdata = mem[cpu_addr];
    else
      cpu_rdata = 32'h00000000;
  end

  always_comb begin
    if (tb_re && (tb_addr < DEPTH))
      tb_rdata = mem[tb_addr];
    else
      tb_rdata = 32'h00000000;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // keep contents unchanged on reset
    end else begin
      if (cpu_we && (cpu_addr < DEPTH)) begin
        mem[cpu_addr] <= cpu_wdata;
      end else if (tb_we && (tb_addr < DEPTH)) begin
        mem[tb_addr] <= tb_wdata;
      end
    end
  end

endmodule

// rtl/regfile.sv
// 8x32 register file:
// - Asynchronous/combinational read ports
// - Synchronous write on posedge clk
// - r0 is hardwired zero (writes ignored)

`timescale 1ns/1ps

module regfile (
  input  logic                                      clk,
  input  logic                                      rst_n,
  input  logic [isa_defs_pkg::REG_ADDR_W-1:0]       rs1_addr,
  input  logic [isa_defs_pkg::REG_ADDR_W-1:0]       rs2_addr,
  output logic [31:0]                                rs1_data,
  output logic [31:0]                                rs2_data,
  input  logic                                      we,
  input  logic [isa_defs_pkg::REG_ADDR_W-1:0]       rd_addr,
  input  logic [31:0]                                rd_data,
  input  logic [isa_defs_pkg::REG_ADDR_W-1:0]       tb_rd_addr,
  output logic [31:0]                                tb_rd_data
);
  import isa_defs_pkg::*;

  logic [31:0] regs [0:REG_COUNT-1];

  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < REG_COUNT; i = i + 1) regs[i] <= 32'h0;
    end else begin
      if (we && (rd_addr != '0)) begin
        regs[rd_addr] <= rd_data;
      end
      regs[0] <= 32'h0;
    end
  end

  always_comb begin
    rs1_data = regs[rs1_addr];
    rs2_data = regs[rs2_addr];
    tb_rd_data = regs[tb_rd_addr];
  end

endmodule

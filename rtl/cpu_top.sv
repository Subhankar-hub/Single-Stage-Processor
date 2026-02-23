// rtl/cpu_top.sv
// Top-level single-cycle CPU. Integrates instruction memory, control unit,
// regfile, ALU, data memory. Provides TB-accessible ports for loading program
// and inspecting memory/registers.

`timescale 1ns/1ps

module cpu_top #(
  parameter int IMEM_DEPTH = 1024,
  parameter int DMEM_DEPTH = 1024
)(
  input  logic                                    clk,
  input  logic                                    rst_n,

  input  logic                                    tb_imem_we,
  input  logic [$clog2(IMEM_DEPTH)-1:0]           tb_imem_addr,
  input  logic [31:0]                              tb_imem_wdata,

  input  logic                                    tb_dmem_we,
  input  logic [$clog2(DMEM_DEPTH)-1:0]           tb_dmem_addr,
  input  logic [31:0]                              tb_dmem_wdata,
  input  logic                                    tb_dmem_re,
  output logic [31:0]                              tb_dmem_rdata,

  input  logic [isa_defs_pkg::REG_ADDR_W-1:0]     tb_reg_rd_addr,
  output logic [31:0]                              tb_reg_rd_data,

  output logic [31:0]                              pc_out,
  output logic [31:0]                              current_instr
);
  import isa_defs_pkg::*;

  // Program counter (word-addressed)
  logic [31:0] pc;
  assign pc_out = pc;

  // Instruction fetch
  logic [31:0] instr;

  instruction_memory #(.DEPTH(IMEM_DEPTH)) imem (
    .clk(clk),
    .rst_n(rst_n),
    .addr_word(pc),
    .instr_out(instr),
    .tb_we(tb_imem_we),
    .tb_addr(tb_imem_addr),
    .tb_wdata(tb_imem_wdata)
  );

  assign current_instr = instr;

  // Control decode
  logic is_itype;
  isa_defs_pkg::alu_op_e alu_op;
  logic reg_write_en, mem_read, mem_write;
  logic [REG_ADDR_W-1:0] rd_addr, rs1_addr, rs2_addr;
  logic signed [IMM_W-1:0] imm16;

  /* verilator lint_off UNUSEDSIGNAL */
  logic unused_is_rtype, unused_is_nop;
  /* verilator lint_on UNUSEDSIGNAL */

  control_unit cu (
    .instr(instr),
    .is_rtype(unused_is_rtype),
    .is_itype(is_itype),
    .is_nop(unused_is_nop),
    .alu_op(alu_op),
    .reg_write_en(reg_write_en),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .rd_addr(rd_addr),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .imm16(imm16)
  );

  // Register file
  logic [31:0] rs1_val, rs2_val;
  logic [31:0] write_back_data;

  regfile rf (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_val),
    .rs2_data(rs2_val),
    .we(reg_write_en),
    .rd_addr(rd_addr),
    .rd_data(write_back_data),
    .tb_rd_addr(tb_reg_rd_addr),
    .tb_rd_data(tb_reg_rd_data)
  );

  // ALU operand selection
  logic [31:0] alu_b_operand;
  always_comb begin
    if (is_itype)
      alu_b_operand = {{16{imm16[15]}}, imm16};
    else
      alu_b_operand = rs2_val;
  end

  logic [31:0] alu_result;
  alu alu_inst (
    .a(rs1_val),
    .b(alu_b_operand),
    .op(alu_op),
    .result(alu_result)
  );

  // Data memory
  logic [31:0] dmem_rdata;
  data_memory #(.DEPTH(DMEM_DEPTH)) dmem (
    .clk(clk),
    .rst_n(rst_n),
    .cpu_we(mem_write),
    .cpu_addr(alu_result[$clog2(DMEM_DEPTH)-1:0]),
    .cpu_wdata(rs2_val),
    .cpu_rdata(dmem_rdata),
    .tb_we(tb_dmem_we),
    .tb_addr(tb_dmem_addr),
    .tb_wdata(tb_dmem_wdata),
    .tb_re(tb_dmem_re),
    .tb_rdata(tb_dmem_rdata)
  );

  // Write-back selection
  always_comb begin
    if (mem_read)
      write_back_data = dmem_rdata;
    else
      write_back_data = alu_result;
  end

  // PC update (single-cycle: increment each clock)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h0;
    end else begin
      pc <= pc + 1;
    end
  end

endmodule

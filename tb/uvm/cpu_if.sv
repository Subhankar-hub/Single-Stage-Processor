// tb/uvm/cpu_if.sv
// Virtual interface between TB and UVM components.

`timescale 1ns / 1ps

interface cpu_if (
    input logic clk,
    input logic rst_n
);
  import isa_defs_pkg::*;

  // TB <-> DUT control signals (mapped to top_tb signals)
  logic                    tb_imem_we;
  logic [$clog2(1024)-1:0] tb_imem_addr;
  logic [            31:0] tb_imem_wdata;

  logic                    tb_dmem_we;
  logic [$clog2(1024)-1:0] tb_dmem_addr;
  logic [            31:0] tb_dmem_wdata;
  logic                    tb_dmem_re;
  logic [            31:0] tb_dmem_rdata;

  logic [  REG_ADDR_W-1:0] tb_reg_rd_addr;
  logic [            31:0] tb_reg_rd_data;

  logic [            31:0] pc_out;
  logic [            31:0] current_instr;

  // modport for driver
  modport drv(
      input clk,
      input rst_n,
      output tb_imem_we,
      output tb_imem_addr,
      output tb_imem_wdata,
      output tb_dmem_we,
      output tb_dmem_addr,
      output tb_dmem_wdata,
      output tb_dmem_re,
      input tb_dmem_rdata,
      output tb_reg_rd_addr,
      input tb_reg_rd_data,
      input pc_out,
      input current_instr
  );

  // modport for monitor (observes)
  modport mon(
      input clk,
      input rst_n,
      input tb_dmem_rdata,
      input tb_reg_rd_data,
      input pc_out,
      input current_instr
  );

endinterface : cpu_if


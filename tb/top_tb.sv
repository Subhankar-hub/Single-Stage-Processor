// tb/top_tb.sv
// Top-level testbench that instantiates cpu_top and runs UVM

`timescale 1ns / 1ps
import uvm_pkg::*;
import isa_defs_pkg::*;
`include "uvm_macros.svh"

module top_tb;

  logic clk;
  logic rst_n;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Interface instance — bridges UVM components to DUT
  cpu_if cif(.clk(clk), .rst_n(rst_n));

  // DUT wired through the interface
  cpu_top #(
      .IMEM_DEPTH(1024),
      .DMEM_DEPTH(1024)
  ) dut (
      .clk           (clk),
      .rst_n         (rst_n),
      .tb_imem_we    (cif.tb_imem_we),
      .tb_imem_addr  (cif.tb_imem_addr),
      .tb_imem_wdata (cif.tb_imem_wdata),
      .tb_dmem_we    (cif.tb_dmem_we),
      .tb_dmem_addr  (cif.tb_dmem_addr),
      .tb_dmem_wdata (cif.tb_dmem_wdata),
      .tb_dmem_re    (cif.tb_dmem_re),
      .tb_dmem_rdata (cif.tb_dmem_rdata),
      .tb_reg_rd_addr(cif.tb_reg_rd_addr),
      .tb_reg_rd_data(cif.tb_reg_rd_data),
      .pc_out        (cif.pc_out),
      .current_instr (cif.current_instr)
  );

  // Reset and interface signal initialisation
  initial begin
    rst_n              = 0;
    cif.tb_imem_we     = 0;
    cif.tb_imem_addr   = '0;
    cif.tb_imem_wdata  = '0;
    cif.tb_dmem_we     = 0;
    cif.tb_dmem_addr   = '0;
    cif.tb_dmem_wdata  = '0;
    cif.tb_dmem_re     = 0;
    cif.tb_reg_rd_addr = '0;
    #50;
    rst_n = 1;
  end

  // Publish virtual interface and launch UVM
  initial begin
    uvm_config_db#(virtual cpu_if)::set(null, "*", "vif", cif);
    run_test();
  end

endmodule

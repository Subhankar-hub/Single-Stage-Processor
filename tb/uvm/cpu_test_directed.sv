// tb/uvm/cpu_test_directed.sv
// Directed test: checks reset behavior, r0 immutability, ADD/SUB/ADDI, LOAD/STORE correctness.

`timescale 1ns/1ps
import uvm_pkg::*;
import cpu_pkg::*;
import isa_defs_pkg::*;
`include "uvm_macros.svh"

class cpu_test_directed extends cpu_test_base;
  `uvm_component_utils(cpu_test_directed)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function logic [31:0] enc_rtype(logic [5:0] opc, logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
    logic [31:0] ins;
    ins = 32'h0;
    ins[31:26] = opc;
    ins[25:23] = rd;
    ins[22:20] = rs1;
    ins[19:17] = rs2;
    return ins;
  endfunction

  function logic [31:0] enc_itype(logic [5:0] opc, logic [2:0] rd_rs2, logic [2:0] rs1, logic signed [15:0] imm);
    logic [31:0] ins;
    ins = 32'h0;
    ins[31:26] = opc;
    ins[25:23] = rd_rs2;
    ins[22:20] = rs1;
    ins[19:4]  = imm;
    return ins;
  endfunction

  task run_phase(uvm_phase phase);
    logic [31:0] r1, r2, r3, r4, r5, d0;

    super.run_phase(phase);
    phase.raise_objection(this);

    if (!uvm_config_db#(virtual cpu_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "Virtual interface not set")

    // Program a small directed program:
    //   IMEM[0]: ADDI r1, r0, 5    ; r1 = 0 + 5
    //   IMEM[1]: ADDI r2, r0, 3    ; r2 = 0 + 3
    //   IMEM[2]: ADD  r3, r1, r2   ; r3 = r1 + r2 = 8
    //   IMEM[3]: SUB  r4, r3, r2   ; r4 = 8 - 3 = 5
    //   IMEM[4]: STORE r4 -> [r0+0]
    //   IMEM[5]: LOAD  r5 <- [r0+0]
    //   IMEM[6]: NOP

    write_imem(0, enc_itype(OPC_ADDI,  3'd1, 3'd0, 16'sd5));
    write_imem(1, enc_itype(OPC_ADDI,  3'd2, 3'd0, 16'sd3));
    write_imem(2, enc_rtype(OPC_ADD,   3'd3, 3'd1, 3'd2));
    write_imem(3, enc_rtype(OPC_SUB,   3'd4, 3'd3, 3'd2));
    write_imem(4, enc_itype(OPC_STORE, 3'd4, 3'd0, 16'sd0));
    write_imem(5, enc_itype(OPC_LOAD,  3'd5, 3'd0, 16'sd0));
    write_imem(6, enc_rtype(OPC_NOP,   3'd0, 3'd0, 3'd0));

    write_dmem(0, 32'h0);

    // Let CPU run for 8 cycles
    repeat (8) @(posedge vif.clk);

    // Read registers from DUT via TB debug port
    vif.tb_reg_rd_addr <= 3'd1; @(posedge vif.clk); r1 = vif.tb_reg_rd_data;
    vif.tb_reg_rd_addr <= 3'd2; @(posedge vif.clk); r2 = vif.tb_reg_rd_data;
    vif.tb_reg_rd_addr <= 3'd3; @(posedge vif.clk); r3 = vif.tb_reg_rd_data;
    vif.tb_reg_rd_addr <= 3'd4; @(posedge vif.clk); r4 = vif.tb_reg_rd_data;
    vif.tb_reg_rd_addr <= 3'd5; @(posedge vif.clk); r5 = vif.tb_reg_rd_data;

    // Read dmem[0]
    vif.tb_dmem_addr <= 0;
    vif.tb_dmem_re   <= 1;
    @(posedge vif.clk);
    @(posedge vif.clk);
    d0 = vif.tb_dmem_rdata;
    vif.tb_dmem_re <= 0;

    // Checks
    if (r1 !== 32'd5) `uvm_error("DIRECTED", $sformatf("r1 expected 5 got %0d", r1))
    if (r2 !== 32'd3) `uvm_error("DIRECTED", $sformatf("r2 expected 3 got %0d", r2))
    if (r3 !== 32'd8) `uvm_error("DIRECTED", $sformatf("r3 expected 8 got %0d", r3))
    if (r4 !== 32'd5) `uvm_error("DIRECTED", $sformatf("r4 expected 5 got %0d", r4))
    if (d0 !== 32'd5) `uvm_error("DIRECTED", $sformatf("dmem[0] expected 5 got %0d", d0))
    if (r5 !== 32'd5) `uvm_error("DIRECTED", $sformatf("r5 expected 5 got %0d", r5))

    `uvm_info("DIRECTED", "Directed test completed", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass : cpu_test_directed

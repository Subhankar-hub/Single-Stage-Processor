// tb/uvm/cpu_driver.sv
// Driver: programs imem/dmem via cpu_if and starts CPU by releasing reset (handled by top_tb).
// For this design the driver is responsible for writing instruction/data memory
// and stepping the clock by letting the TB clock run (clock is free-running).

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
`include "uvm_macros.svh"

class cpu_driver extends uvm_driver #(cpu_trans);
  virtual cpu_if.drv vif;

  `uvm_component_utils(cpu_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // simple helper to write instruction memory (synchronous write; must be held for one clk)
  task automatic write_imem(bit [$clog2(1024)-1:0] addr, logic [31:0] data);
    @(posedge vif.clk);
    vif.tb_imem_addr <= addr;
    vif.tb_imem_wdata <= data;
    vif.tb_imem_we <= 1;
    @(posedge vif.clk);
    vif.tb_imem_we <= 0;
    @(posedge vif.clk);
  endtask

  task automatic write_dmem(bit [$clog2(1024)-1:0] addr, logic [31:0] data);
    @(posedge vif.clk);
    vif.tb_dmem_addr <= addr;
    vif.tb_dmem_wdata <= data;
    vif.tb_dmem_we <= 1;
    @(posedge vif.clk);
    vif.tb_dmem_we <= 0;
    @(posedge vif.clk);
  endtask

  // run: accept sequence items for memory programming
  virtual task run_phase(uvm_phase phase);
    cpu_trans tr;
    super.run_phase(phase);
    if (!uvm_config_db#(virtual cpu_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRIVER", "Virtual interface not set")
    end

    forever begin
      seq_item_port.get_next_item(tr);
      // interpret transaction: a transaction instr with pc==special used for mem write
      // We'll use convention: if tr.pc < 1024 and tr.instr's high byte == 8'hAA -> imem write
      // But to keep simple we assume tests call specific driver methods directly via sequences.
      seq_item_port.item_done();
    end
  endtask

endclass : cpu_driver


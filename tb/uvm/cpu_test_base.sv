// tb/uvm/cpu_test_base.sv
// Base test that sets up virtual interface and configuration.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
import isa_defs_pkg::*;
`include "uvm_macros.svh"

class cpu_test_base extends uvm_test;
  cpu_env env;
  virtual cpu_if vif;

  `uvm_component_utils(cpu_test_base)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = cpu_env::type_id::create("env", this);

    if (!uvm_config_db#(virtual cpu_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("TEST", "Virtual interface not provided via config DB")
    end

    uvm_config_db#(virtual cpu_if)::set(this, "env.agent", "vif", vif);
  endfunction

  task write_imem(int addr, logic [31:0] data);
    @(posedge vif.clk);
    vif.tb_imem_addr  <= addr;
    vif.tb_imem_wdata <= data;
    vif.tb_imem_we    <= 1;
    @(posedge vif.clk);
    vif.tb_imem_we <= 0;
  endtask

  task write_dmem(int addr, logic [31:0] data);
    @(posedge vif.clk);
    vif.tb_dmem_addr  <= addr;
    vif.tb_dmem_wdata <= data;
    vif.tb_dmem_we    <= 1;
    @(posedge vif.clk);
    vif.tb_dmem_we <= 0;
  endtask

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("TEST", $sformatf("Running %s", get_full_name()), UVM_LOW)
  endtask

endclass : cpu_test_base

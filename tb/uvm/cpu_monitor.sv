// tb/uvm/cpu_monitor.sv
// Monitor that observes PC and instruction each cycle and samples architectural state
// via TB debug read ports and forwards transactions to scoreboard.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
`include "uvm_macros.svh"

class cpu_monitor extends uvm_component;
  virtual cpu_if.mon vif;
  uvm_analysis_port #(cpu_trans) ap;

  `uvm_component_utils(cpu_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    cpu_trans tr;
    super.run_phase(phase);
    if (!uvm_config_db#(virtual cpu_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON", "Virtual interface not set")
    end

    forever begin
      @(posedge vif.clk);
      if (!vif.rst_n) continue;
      tr = cpu_trans::type_id::create("tr");
      tr.pc = vif.pc_out;
      tr.instr = vif.current_instr;
      ap.write(tr);
    end
  endtask

endclass : cpu_monitor


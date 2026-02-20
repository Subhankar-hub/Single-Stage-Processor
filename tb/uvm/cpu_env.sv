// tb/uvm/cpu_env.sv
// UVM environment: instantiates agent and scoreboard, connects monitor to scoreboard.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
`include "uvm_macros.svh"

class cpu_env extends uvm_env;
  cpu_agent agent;
  cpu_scoreboard scoreboard;

  `uvm_component_utils(cpu_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = cpu_agent::type_id::create("agent", this);
    scoreboard = cpu_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // connect monitor analysis port to scoreboard
    agent.monitor.ap.connect(scoreboard.analysis_export);
  endfunction

endclass : cpu_env


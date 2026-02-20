// tb/uvm/cpu_agent.sv
// Simple agent that instantiates driver and monitor.

`timescale 1ns / 1ps
import uvm_pkg::*;
import cpu_pkg::*;
`include "uvm_macros.svh"

class cpu_agent extends uvm_component;
  virtual cpu_if vif;
  cpu_driver driver;
  cpu_monitor monitor;

  `uvm_component_utils(cpu_agent)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver  = cpu_driver::type_id::create("driver", this);
    monitor = cpu_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // pass virtual interface to driver and monitor via config DB
    uvm_config_db#(virtual cpu_if)::set(this, "driver", "vif", vif);
    uvm_config_db#(virtual cpu_if)::set(this, "monitor", "vif", vif);
  endfunction

endclass : cpu_agent


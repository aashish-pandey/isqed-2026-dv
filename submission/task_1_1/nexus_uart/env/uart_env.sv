import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)

  tl_ul_agent     m_tl_agent;
  uart_agent      m_uart_agent;
  uart_scoreboard m_scoreboard;
  uart_coverage   m_coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_tl_agent   = tl_ul_agent::type_id::create("m_tl_agent",   this);
    m_uart_agent = uart_agent::type_id::create("m_uart_agent",  this);
    m_scoreboard = uart_scoreboard::type_id::create("m_scoreboard", this);
    m_coverage   = uart_coverage::type_id::create("m_coverage",  this);
  endfunction

  function void connect_phase(uvm_phase phase);
    m_tl_agent.ap_write.connect(m_scoreboard.aimp_write);
    m_tl_agent.ap_read.connect(m_scoreboard.aimp_read);
    m_tl_agent.ap_write.connect(m_coverage.analysis_export);
    m_tl_agent.ap_read.connect(m_coverage.analysis_export);
  endfunction

endclass
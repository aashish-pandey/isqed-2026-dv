//=============================================================================
// gpio_env.sv
// Top-level UVM environment for bastion_gpio.
// Instantiates TL-UL agent, GPIO agent, scoreboard, and coverage collector.
//=============================================================================
`ifndef GPIO_ENV_SV
`define GPIO_ENV_SV

class gpio_env extends uvm_env;
  `uvm_component_utils(gpio_env)

  // ── Sub-components ────────────────────────────────────────────────────────
  tl_ul_agent     m_tl_agent;
  gpio_agent      m_gpio_agent;
  gpio_scoreboard m_scoreboard;
  gpio_coverage   m_coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_tl_agent   = tl_ul_agent::type_id::create("m_tl_agent",   this);
    m_gpio_agent = gpio_agent::type_id::create("m_gpio_agent", this);
    m_scoreboard = gpio_scoreboard::type_id::create("m_scoreboard", this);
    m_coverage   = gpio_coverage::type_id::create("m_coverage",   this);

    // Both agents active by default
    uvm_config_db #(uvm_active_passive_enum)::set(
      this, "m_tl_agent",   "is_active", UVM_ACTIVE);
    uvm_config_db #(uvm_active_passive_enum)::set(
      this, "m_gpio_agent", "is_active", UVM_ACTIVE);
  endfunction

  function void connect_phase(uvm_phase phase);
    // TL-UL monitor → scoreboard
    m_tl_agent.ap_write.connect(m_scoreboard.aimp_write);
    m_tl_agent.ap_read.connect(m_scoreboard.aimp_read);

    // TL-UL monitor → coverage (writes and reads both feed coverage)
    m_tl_agent.ap_write.connect(m_coverage.analysis_export);
    m_tl_agent.ap_read.connect(m_coverage.analysis_export);
  endfunction

endclass

`endif // GPIO_ENV_SV

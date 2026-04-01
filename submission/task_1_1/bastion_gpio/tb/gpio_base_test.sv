import uvm_pkg::*;
`include "uvm_macros.svh"

class gpio_base_test extends uvm_test;
  `uvm_component_utils(gpio_base_test)

  gpio_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = gpio_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    tl_ul_base_seq tl_seq;
    gpio_toggle_seq gpio_seq;
    bit [31:0] rdata;

    phase.raise_objection(this);

    tl_seq = tl_ul_base_seq::type_id::create("tl_seq");
    gpio_seq = gpio_toggle_seq::type_id::create("gpio_seq");

    // VP-GPIO-001: configure all pins as output, write pattern
    tl_seq.start(env.m_tl_agent.sequencer);

    // Write DIR = all outputs
    fork
      begin
        tl_ul_base_seq s = tl_ul_base_seq::type_id::create("s");
        s.start(env.m_tl_agent.sequencer);
      end
    join

    // Use write_reg/read_reg directly via inline sequence
    begin
      tl_ul_write_seq wr;
      tl_ul_read_seq  rd;

      // VP-GPIO-001: all outputs
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h08; wr.data = 32'hFFFFFFFF;
      wr.start(env.m_tl_agent.sequencer);

      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h04; wr.data = 32'hA5A5A5A5;
      wr.start(env.m_tl_agent.sequencer);

      rd = tl_ul_read_seq::type_id::create("rd");
      rd.addr = 32'h04;
      rd.start(env.m_tl_agent.sequencer);
      `uvm_info("TEST", $sformatf("DATA_OUT readback=0x%08h", rd.rdata), UVM_NONE)

      // VP-GPIO-004: rising edge interrupt
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h18; wr.data = 32'hFFFFFFFF;
      wr.start(env.m_tl_agent.sequencer);

      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h10; wr.data = 32'hFFFFFFFF;
      wr.start(env.m_tl_agent.sequencer);

      // Drive gpio_i toggle via gpio agent
      gpio_seq.pin_sel = 32'hFFFFFFFF;
      gpio_seq.hold    = 8;
      gpio_seq.start(env.m_gpio_agent.sequencer);

      // Read INTR_STATE
      rd = tl_ul_read_seq::type_id::create("rd");
      rd.addr = 32'h0C;
      rd.start(env.m_tl_agent.sequencer);
      `uvm_info("TEST", $sformatf("INTR_STATE=0x%08h", rd.rdata), UVM_NONE)

      // VP-GPIO-009: masked write lower
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h28; wr.data = 32'hFF00_0055;
      wr.start(env.m_tl_agent.sequencer);

      rd = tl_ul_read_seq::type_id::create("rd");
      rd.addr = 32'h04;
      rd.start(env.m_tl_agent.sequencer);
      `uvm_info("TEST", $sformatf("DATA_OUT after masked write=0x%08h", rd.rdata), UVM_NONE)

      // VP-GPIO-010: masked write upper
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h2C; wr.data = 32'hFF00_00AA;
      wr.start(env.m_tl_agent.sequencer);

      rd = tl_ul_read_seq::type_id::create("rd");
      rd.addr = 32'h04;
      rd.start(env.m_tl_agent.sequencer);
      `uvm_info("TEST", $sformatf("DATA_OUT after upper masked write=0x%08h", rd.rdata), UVM_NONE)

      // VP-GPIO-007: level high interrupt
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h20; wr.data = 32'h000000FF;
      wr.start(env.m_tl_agent.sequencer);

      // VP-GPIO-008: level low interrupt
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h24; wr.data = 32'h000000FF;
      wr.start(env.m_tl_agent.sequencer);

      // Clear INTR_STATE W1C
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h0C; wr.data = 32'hFFFFFFFF;
      wr.start(env.m_tl_agent.sequencer);

      // INTR_TEST
      wr = tl_ul_write_seq::type_id::create("wr");
      wr.addr = 32'h14; wr.data = 32'hDEADBEEF;
      wr.start(env.m_tl_agent.sequencer);

      rd = tl_ul_read_seq::type_id::create("rd");
      rd.addr = 32'h0C;
      rd.start(env.m_tl_agent.sequencer);
      `uvm_info("TEST", $sformatf("INTR_STATE after test=0x%08h", rd.rdata), UVM_NONE)
    end

    phase.drop_objection(this);
  endtask

endclass
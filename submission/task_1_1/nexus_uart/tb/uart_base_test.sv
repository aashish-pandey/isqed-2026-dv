import uvm_pkg::*;
`include "uvm_macros.svh"

class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uart_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = uart_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    tl_ul_write_seq wr;
    tl_ul_read_seq  rd;
    uart_single_byte_seq uart_seq;
    bit [31:0] ctrl_val;

    phase.raise_objection(this);

    // Configure UART: tx_en=1 rx_en=1 baud_div=8 loopback=1
    // CTRL bits: [0]=tx_en [1]=rx_en [17:2]=baud_div [21]=loopback
    ctrl_val = (1 << 0) | (1 << 1) | (8 << 2) | (1 << 21);
    wr = tl_ul_write_seq::type_id::create("wr");
    wr.addr = 32'h00; wr.data = ctrl_val;
    wr.start(env.m_tl_agent.sequencer);

    // Readback CTRL
    rd = tl_ul_read_seq::type_id::create("rd");
    rd.addr = 32'h00;
    rd.start(env.m_tl_agent.sequencer);
    `uvm_info("TEST", $sformatf("CTRL readback=0x%08h", rd.rdata), UVM_NONE)

    // Enable all interrupts
    wr = tl_ul_write_seq::type_id::create("wr");
    wr.addr = 32'h18; wr.data = 32'h7F;
    wr.start(env.m_tl_agent.sequencer);

    // Write byte to TXDATA — loopback will send it to RX
    wr = tl_ul_write_seq::type_id::create("wr");
    wr.addr = 32'h08; wr.data = 32'hA5;
    wr.start(env.m_tl_agent.sequencer);

    // Wait for transmission
    repeat(300) @(posedge uart_if_inst.clk);

    // Read STATUS
    rd = tl_ul_read_seq::type_id::create("rd");
    rd.addr = 32'h04;
    rd.start(env.m_tl_agent.sequencer);
    `uvm_info("TEST", $sformatf("STATUS=0x%08h", rd.rdata), UVM_NONE)

    // Read RXDATA
    rd = tl_ul_read_seq::type_id::create("rd");
    rd.addr = 32'h0C;
    rd.start(env.m_tl_agent.sequencer);
    `uvm_info("TEST", $sformatf("RXDATA=0x%08h", rd.rdata), UVM_NONE)

    // Read INTR_STATE
    rd = tl_ul_read_seq::type_id::create("rd");
    rd.addr = 32'h14;
    rd.start(env.m_tl_agent.sequencer);
    `uvm_info("TEST", $sformatf("INTR_STATE=0x%08h", rd.rdata), UVM_NONE)

    // INTR_TEST
    wr = tl_ul_write_seq::type_id::create("wr");
    wr.addr = 32'h1C; wr.data = 32'h7F;
    wr.start(env.m_tl_agent.sequencer);

    // Set FIFO watermarks
    wr = tl_ul_write_seq::type_id::create("wr");
    wr.addr = 32'h10; wr.data = 32'h00000042;
    wr.start(env.m_tl_agent.sequencer);

    rd = tl_ul_read_seq::type_id::create("rd");
    rd.addr = 32'h10;
    rd.start(env.m_tl_agent.sequencer);
    `uvm_info("TEST", $sformatf("FIFO_CTRL=0x%08h", rd.rdata), UVM_NONE)

    // Send byte via UART agent RX stimulus
    uart_seq = uart_single_byte_seq::type_id::create("uart_seq");
    uart_seq.data     = 8'hB7;
    uart_seq.baud_div = 8;
    uart_seq.start(env.m_uart_agent.sequencer);

    repeat(500) @(posedge uart_if_inst.clk);

    phase.drop_objection(this);
  endtask

endclass
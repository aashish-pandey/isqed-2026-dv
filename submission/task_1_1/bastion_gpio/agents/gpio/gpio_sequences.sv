//=============================================================================
// gpio_sequences.sv — GPIO stimulus sequences
//=============================================================================
`ifndef GPIO_SEQUENCES_SV
`define GPIO_SEQUENCES_SV

//-----------------------------------------------------------------------------
// gpio_base_seq
//-----------------------------------------------------------------------------
class gpio_base_seq extends uvm_sequence #(gpio_seq_item);
  `uvm_object_utils(gpio_base_seq)

  function new(string name = "gpio_base_seq");
    super.new(name);
  endfunction

  // Drive all 32 pins to a specific value for N cycles
  task drive_all(bit [31:0] values, int unsigned cycles = 5);
    gpio_seq_item item = gpio_seq_item::type_id::create("item");
    item.pin_mask    = 32'hFFFFFFFF;
    item.pin_values  = values;
    item.hold_cycles = cycles;
    start_item(item);
    finish_item(item);
  endtask

  // Drive a single pin
  task drive_pin(int unsigned pin, bit val, int unsigned cycles = 5);
    gpio_seq_item item = gpio_seq_item::type_id::create("item");
    item.pin_mask    = 32'h1 << pin;
    item.pin_values  = val ? (32'h1 << pin) : 32'h0;
    item.hold_cycles = cycles;
    start_item(item);
    finish_item(item);
  endtask

endclass

//-----------------------------------------------------------------------------
// gpio_toggle_seq — toggle all pins high then low (exercises edge detection)
//-----------------------------------------------------------------------------
class gpio_toggle_seq extends gpio_base_seq;
  `uvm_object_utils(gpio_toggle_seq)

  bit [31:0] pin_sel = 32'hFFFFFFFF;  // which pins to toggle
  int unsigned hold  = 6;

  function new(string name = "gpio_toggle_seq");
    super.new(name);
  endfunction

  task body();
    // Drive selected pins low first (establish baseline)
    drive_all(32'h0, hold);
    // Rising edge
    begin
      gpio_seq_item item = gpio_seq_item::type_id::create("rise");
      item.pin_mask    = pin_sel;
      item.pin_values  = pin_sel;
      item.hold_cycles = hold;
      start_item(item); finish_item(item);
    end
    // Falling edge
    begin
      gpio_seq_item item = gpio_seq_item::type_id::create("fall");
      item.pin_mask    = pin_sel;
      item.pin_values  = 32'h0;
      item.hold_cycles = hold;
      start_item(item); finish_item(item);
    end
  endtask

endclass

//-----------------------------------------------------------------------------
// gpio_random_seq — randomized pin stimulus
//-----------------------------------------------------------------------------
class gpio_random_seq extends gpio_base_seq;
  `uvm_object_utils(gpio_random_seq)

  int unsigned num_txns = 16;

  function new(string name = "gpio_random_seq");
    super.new(name);
  endfunction

  task body();
    gpio_seq_item item;
    repeat (num_txns) begin
      item = gpio_seq_item::type_id::create("rand_item");
      if (!item.randomize())
        `uvm_error("RAND_FAIL", "gpio_seq_item randomization failed")
      start_item(item);
      finish_item(item);
    end
  endtask

endclass

`endif // GPIO_SEQUENCES_SV

//=============================================================================
// gpio_agent.sv
//=============================================================================
`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;
  `uvm_component_utils(gpio_agent)

  uvm_sequencer #(gpio_seq_item) sequencer;
  gpio_driver                    driver;
  gpio_monitor                   monitor;

  uvm_analysis_port #(gpio_seq_item) ap_gpio;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = gpio_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = uvm_sequencer #(gpio_seq_item)::type_id::create("sequencer", this);
      driver    = gpio_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    ap_gpio = monitor.ap_gpio;
  endfunction

endclass

`endif // GPIO_AGENT_SV

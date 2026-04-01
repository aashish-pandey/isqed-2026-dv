//=============================================================================
// gpio_monitor.sv
// Observes gpio_i, gpio_o, gpio_oe_o, and intr_o.
// Publishes gpio_seq_item on ap_gpio when it detects a pin value change.
//=============================================================================
`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;
  `uvm_component_utils(gpio_monitor)

  virtual interface gpio_if vif;

  uvm_analysis_port #(gpio_seq_item) ap_gpio;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap_gpio = new("ap_gpio", this);
    if (!uvm_config_db #(virtual gpio_if)::get(this, "", "gpio_vif", vif))
      `uvm_fatal("NO_VIF", {"gpio_monitor: gpio_vif not found for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    bit [31:0] prev_gpio_i = 32'h0;
    @(posedge vif.rst_n);
    repeat(4) @(posedge vif.clk);  // let synchronizer settle

    forever begin
      @(posedge vif.clk);
      if (vif.gpio_i !== prev_gpio_i) begin
        gpio_seq_item obs;
        obs            = gpio_seq_item::type_id::create("obs");
        obs.pin_values = vif.gpio_i;
        obs.pin_mask   = 32'hFFFFFFFF;
        obs.hold_cycles = 1;
        ap_gpio.write(obs);
        `uvm_info("GPIO_MON",
          $sformatf("gpio_i changed: 0x%08h → 0x%08h | gpio_o=0x%08h oe=0x%08h intr=0x%08h",
                    prev_gpio_i, vif.gpio_i, vif.gpio_o, vif.gpio_oe_o, vif.intr_o), UVM_MEDIUM)
        prev_gpio_i = vif.gpio_i;
      end
    end
  endtask

endclass

`endif // GPIO_MONITOR_SV

"""
gpio_ref_model.py — Behavioral reference model for bastion_gpio.

Models all CSR state and predicts:
  - gpio_o  (output pin values)
  - gpio_oe_o (output enable)
  - intr_o  (interrupt output per pin)
  - DATA_IN readback (after synchronizer latency)

Key RTL behaviors modeled:
  - Two-stage synchronizer: gpio_i visible in DATA_IN after 2 clock cycles
  - Edge detection: rising/falling detected on synchronized value
  - INTR_TEST auto-clears after one cycle
  - INTR_STATE is W1C; level interrupts re-assert if condition still holds
  - MASKED_OUT_LOWER/UPPER use upper 16 bits as write mask
  - DATA_IN writes silently ignored (no bus error)
"""

# ── Register offsets ──────────────────────────────────────────────────────────
ADDR_DATA_IN              = 0x00
ADDR_DATA_OUT             = 0x04
ADDR_DIR                  = 0x08
ADDR_INTR_STATE           = 0x0C
ADDR_INTR_ENABLE          = 0x10
ADDR_INTR_TEST            = 0x14
ADDR_INTR_CTRL_EN_RISING  = 0x18
ADDR_INTR_CTRL_EN_FALLING = 0x1C
ADDR_INTR_CTRL_EN_LVLHIGH = 0x20
ADDR_INTR_CTRL_EN_LVLLOW  = 0x24
ADDR_MASKED_OUT_LOWER     = 0x28
ADDR_MASKED_OUT_UPPER     = 0x2C

MASK32 = 0xFFFFFFFF


class GpioRefModel:
    """
    Cycle-accurate reference model for bastion_gpio.
    Call clock_tick() once per rising clock edge to advance state.
    Call csr_write() / csr_read() to model TL-UL accesses (same cycle as tick).
    Call set_gpio_i() to drive external pin values.
    """

    def __init__(self):
        self.reset()

    def reset(self):
        # CSR state
        self.reg_data_out             = 0
        self.reg_dir                  = 0
        self.reg_intr_state           = 0
        self.reg_intr_enable          = 0
        self.reg_intr_test            = 0
        self.reg_intr_ctrl_en_rising  = 0
        self.reg_intr_ctrl_en_falling = 0
        self.reg_intr_ctrl_en_lvlhigh = 0
        self.reg_intr_ctrl_en_lvllow  = 0

        # Two-stage synchronizer pipeline
        self._gpio_i_raw  = 0   # current external input
        self._sync_q1     = 0   # first stage
        self._sync_q2     = 0   # second stage (visible as DATA_IN)
        self._sync_prev   = 0   # previous sync_q2 for edge detection

        # Pending writes this cycle (applied at clock edge)
        self._pending_writes = {}
        self._pending_gpio_i = None

    # ── External GPIO input ───────────────────────────────────────────────────

    def set_gpio_i(self, value):
        """Set the raw gpio_i value. Propagates through synchronizer on next ticks."""
        self._gpio_i_raw = value & MASK32

    # ── CSR access ────────────────────────────────────────────────────────────

    def csr_write(self, addr, data):
        """
        Model a CSR write. Returns (error_flag).
        DATA_IN writes are silently ignored (no error per spec).
        """
        addr = addr & ~3   # word-align
        data = data & MASK32

        if addr == ADDR_DATA_IN:
            return False   # silently ignored

        elif addr == ADDR_DATA_OUT:
            self.reg_data_out = data

        elif addr == ADDR_DIR:
            self.reg_dir = data

        elif addr == ADDR_INTR_STATE:
            # W1C: clear bits where data=1
            self.reg_intr_state = (self.reg_intr_state & ~data) & MASK32

        elif addr == ADDR_INTR_ENABLE:
            self.reg_intr_enable = data

        elif addr == ADDR_INTR_TEST:
            # Sets INTR_STATE bits; reg_intr_test auto-clears next cycle
            self.reg_intr_test   = data
            self.reg_intr_state  = (self.reg_intr_state | data) & MASK32

        elif addr == ADDR_INTR_CTRL_EN_RISING:
            self.reg_intr_ctrl_en_rising = data

        elif addr == ADDR_INTR_CTRL_EN_FALLING:
            self.reg_intr_ctrl_en_falling = data

        elif addr == ADDR_INTR_CTRL_EN_LVLHIGH:
            self.reg_intr_ctrl_en_lvlhigh = data

        elif addr == ADDR_INTR_CTRL_EN_LVLLOW:
            self.reg_intr_ctrl_en_lvllow = data

        elif addr == ADDR_MASKED_OUT_LOWER:
            mask = (data >> 16) & 0xFFFF
            vals =  data        & 0xFFFF
            for i in range(16):
                if (mask >> i) & 1:
                    if (vals >> i) & 1:
                        self.reg_data_out |=  (1 << i)
                    else:
                        self.reg_data_out &= ~(1 << i)
            self.reg_data_out &= MASK32

        elif addr == ADDR_MASKED_OUT_UPPER:
            mask = (data >> 16) & 0xFFFF
            vals =  data        & 0xFFFF
            for i in range(16):
                if (mask >> i) & 1:
                    if (vals >> i) & 1:
                        self.reg_data_out |=  (1 << (i + 16))
                    else:
                        self.reg_data_out &= ~(1 << (i + 16))
            self.reg_data_out &= MASK32

        return False

    def csr_read(self, addr):
        """Model a CSR read. Returns (rdata, error_flag)."""
        addr = addr & ~3

        if addr == ADDR_DATA_IN:
            return self._sync_q2, False
        elif addr == ADDR_DATA_OUT:
            return self.reg_data_out, False
        elif addr == ADDR_DIR:
            return self.reg_dir, False
        elif addr == ADDR_INTR_STATE:
            return self.reg_intr_state, False
        elif addr == ADDR_INTR_ENABLE:
            return self.reg_intr_enable, False
        elif addr == ADDR_INTR_TEST:
            return self.reg_intr_test, False
        elif addr == ADDR_INTR_CTRL_EN_RISING:
            return self.reg_intr_ctrl_en_rising, False
        elif addr == ADDR_INTR_CTRL_EN_FALLING:
            return self.reg_intr_ctrl_en_falling, False
        elif addr == ADDR_INTR_CTRL_EN_LVLHIGH:
            return self.reg_intr_ctrl_en_lvlhigh, False
        elif addr == ADDR_INTR_CTRL_EN_LVLLOW:
            return self.reg_intr_ctrl_en_lvllow, False
        elif addr == ADDR_MASKED_OUT_LOWER:
            return self.reg_data_out & 0xFFFF, False
        elif addr == ADDR_MASKED_OUT_UPPER:
            return (self.reg_data_out >> 16) & 0xFFFF, False
        else:
            return 0, False   # unknown address: return 0, no error

    # ── Clock tick ────────────────────────────────────────────────────────────

    def clock_tick(self):
        """
        Advance model by one clock cycle.
        Call this after applying all CSR writes for the current cycle.
        """
        # 1. Advance two-stage synchronizer
        self._sync_prev = self._sync_q2
        self._sync_q2   = self._sync_q1
        self._sync_q1   = self._gpio_i_raw

        # 2. Edge detection
        rising  = self._sync_q2 & ~self._sync_prev & MASK32
        falling = ~self._sync_q2 & self._sync_prev & MASK32

        # 3. Interrupt source combination
        intr_rising  = rising  & self.reg_intr_ctrl_en_rising
        intr_falling = falling & self.reg_intr_ctrl_en_falling
        intr_lvlhigh = self._sync_q2  & self.reg_intr_ctrl_en_lvlhigh
        intr_lvllow  = (~self._sync_q2 & MASK32) & self.reg_intr_ctrl_en_lvllow
        intr_combined = (intr_rising | intr_falling | intr_lvlhigh | intr_lvllow) & MASK32

        # 4. Set INTR_STATE from hw events (W1C clear was already applied in csr_write)
        self.reg_intr_state = (self.reg_intr_state | intr_combined) & MASK32

        # 5. Auto-clear INTR_TEST
        self.reg_intr_test = 0

    # ── Predicted outputs ─────────────────────────────────────────────────────

    @property
    def gpio_o(self):
        return self.reg_data_out

    @property
    def gpio_oe_o(self):
        return self.reg_dir

    @property
    def intr_o(self):
        return (self.reg_intr_state & self.reg_intr_enable) & MASK32

    @property
    def data_in(self):
        return self._sync_q2


# ── Standalone checker (used by scoreboard) ───────────────────────────────────

class GpioChecker:
    """
    Transaction-level checker. Feed observed DUT outputs and predicted outputs,
    reports mismatches.
    """

    def __init__(self):
        self.errors   = 0
        self.checks   = 0

    def check_read(self, addr, dut_rdata, ref_rdata, context=""):
        self.checks += 1
        if (dut_rdata & MASK32) != (ref_rdata & MASK32):
            self.errors += 1
            print(f"[MISMATCH] READ addr=0x{addr:08X} "
                  f"dut=0x{dut_rdata:08X} ref=0x{ref_rdata:08X} {context}")
        else:
            print(f"[OK]       READ addr=0x{addr:08X} data=0x{dut_rdata:08X} {context}")

    def check_outputs(self, dut_gpio_o, dut_gpio_oe, dut_intr_o,
                      ref_gpio_o, ref_gpio_oe, ref_intr_o, context=""):
        self.checks += 3
        for name, dut_val, ref_val in [
            ("gpio_o",    dut_gpio_o,  ref_gpio_o),
            ("gpio_oe_o", dut_gpio_oe, ref_gpio_oe),
            ("intr_o",    dut_intr_o,  ref_intr_o),
        ]:
            if (dut_val & MASK32) != (ref_val & MASK32):
                self.errors += 1
                print(f"[MISMATCH] {name} dut=0x{dut_val:08X} ref=0x{ref_val:08X} {context}")

    def report(self):
        print(f"\n=== GPIO Checker: {self.checks} checks, {self.errors} errors ===")
        return self.errors == 0


if __name__ == "__main__":
    # Quick self-test of the reference model
    m = GpioRefModel()

    # Test 1: reset values
    assert m.gpio_o == 0
    assert m.gpio_oe_o == 0
    assert m.intr_o == 0

    # Test 2: set direction and output
    m.csr_write(ADDR_DIR,      0xFFFF0000)  # upper 16 = output
    m.csr_write(ADDR_DATA_OUT, 0xABCD0000)
    assert m.gpio_o    == 0xABCD0000
    assert m.gpio_oe_o == 0xFFFF0000

    # Test 3: synchronizer latency
    m.set_gpio_i(0x00000001)
    assert m.data_in == 0            # not yet
    m.clock_tick()
    assert m.data_in == 0            # still in q1
    m.clock_tick()
    assert m.data_in == 0x00000001   # now in q2

    # Test 4: rising edge interrupt
    m.csr_write(ADDR_INTR_CTRL_EN_RISING, 0x00000001)
    m.csr_write(ADDR_INTR_ENABLE,         0x00000001)
    m.set_gpio_i(0x0)
    m.clock_tick(); m.clock_tick()   # settle to 0
    m.csr_write(ADDR_INTR_STATE, 0xFFFFFFFF)  # clear
    m.set_gpio_i(0x1)
    m.clock_tick(); m.clock_tick(); m.clock_tick()
    assert m.intr_o & 1, f"Rising edge intr should fire, intr_o=0x{m.intr_o:08X}"

    # Test 5: masked write lower
    m2 = GpioRefModel()
    m2.csr_write(ADDR_DATA_OUT, 0xFFFFFFFF)
    # mask=0x0003 (bits 0,1), data=0x0001 (set bit0, clear bit1)
    m2.csr_write(ADDR_MASKED_OUT_LOWER, (0x0003 << 16) | 0x0001)
    assert m2.gpio_o & 0xFFFF == 0xFFFD | 0x0001, \
        f"Masked write failed: 0x{m2.gpio_o:08X}"

    print("All self-tests passed.")

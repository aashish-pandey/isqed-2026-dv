"""
gpio_ref_model.py
Behavioral reference model for bastion_gpio.
Models all CSR state and predicts register read values.
"""

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

    def __init__(self):
        self.reset()

    def reset(self):
        self.reg_data_out             = 0
        self.reg_dir                  = 0
        self.reg_intr_state           = 0
        self.reg_intr_enable          = 0
        self.reg_intr_ctrl_en_rising  = 0
        self.reg_intr_ctrl_en_falling = 0
        self.reg_intr_ctrl_en_lvlhigh = 0
        self.reg_intr_ctrl_en_lvllow  = 0
        self._sync_q1   = 0
        self._sync_q2   = 0
        self._sync_prev = 0
        self._gpio_i    = 0

    def set_gpio_i(self, value):
        self._gpio_i = value & MASK32

    def clock_tick(self):
        # Advance two-stage synchronizer
        self._sync_prev = self._sync_q2
        self._sync_q2   = self._sync_q1
        self._sync_q1   = self._gpio_i

        # Edge detection
        rising  = self._sync_q2 & ~self._sync_prev & MASK32
        falling = ~self._sync_q2 & self._sync_prev & MASK32

        # Interrupt sources
        intr = (rising  & self.reg_intr_ctrl_en_rising)  | \
               (falling & self.reg_intr_ctrl_en_falling) | \
               (self._sync_q2        & self.reg_intr_ctrl_en_lvlhigh) | \
               ((~self._sync_q2 & MASK32) & self.reg_intr_ctrl_en_lvllow)

        self.reg_intr_state = (self.reg_intr_state | intr) & MASK32

    def csr_write(self, addr, data):
        addr = addr & ~3
        data = data & MASK32
        if addr == ADDR_DATA_IN:
            pass  # silently ignored
        elif addr == ADDR_DATA_OUT:
            self.reg_data_out = data
        elif addr == ADDR_DIR:
            self.reg_dir = data
        elif addr == ADDR_INTR_STATE:
            self.reg_intr_state = (self.reg_intr_state & ~data) & MASK32
        elif addr == ADDR_INTR_ENABLE:
            self.reg_intr_enable = data
        elif addr == ADDR_INTR_TEST:
            self.reg_intr_state = (self.reg_intr_state | data) & MASK32
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

    def csr_read(self, addr):
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
            return 0, False

    @property
    def gpio_o(self):
        return self.reg_data_out

    @property
    def gpio_oe_o(self):
        return self.reg_dir

    @property
    def intr_o(self):
        return (self.reg_intr_state & self.reg_intr_enable) & MASK32


if __name__ == "__main__":
    m = GpioRefModel()
    assert m.gpio_o == 0
    assert m.gpio_oe_o == 0

    m.csr_write(ADDR_DATA_OUT, 0xA5A5A5A5)
    assert m.gpio_o == 0xA5A5A5A5

    m.csr_write(ADDR_DIR, 0xFFFFFFFF)
    assert m.gpio_oe_o == 0xFFFFFFFF

    m.csr_write(ADDR_MASKED_OUT_LOWER, (0x00FF << 16) | 0x0055)
    assert (m.gpio_o & 0xFF) == 0x55

    m.set_gpio_i(0x1)
    m.clock_tick(); m.clock_tick(); m.clock_tick()
    assert m._sync_q2 == 0x1

    print("All self-tests passed.")
#include "defs.h"

#define NETSTREAM_BASE    0x30000000UL

#define NS_TCAM_W0        (*(volatile uint32_t*)(NETSTREAM_BASE + 0x00))
#define NS_TCAM_W1        (*(volatile uint32_t*)(NETSTREAM_BASE + 0x04))
#define NS_TCAM_W2        (*(volatile uint32_t*)(NETSTREAM_BASE + 0x08))
#define NS_TCAM_W3        (*(volatile uint32_t*)(NETSTREAM_BASE + 0x0C))
#define NS_TCAM_VAL_ADDR  (*(volatile uint32_t*)(NETSTREAM_BASE + 0x10))
#define NS_TCAM_MASK_ADDR (*(volatile uint32_t*)(NETSTREAM_BASE + 0x14))
#define NS_ACTION_W0      (*(volatile uint32_t*)(NETSTREAM_BASE + 0x20))
#define NS_ACTION_W1      (*(volatile uint32_t*)(NETSTREAM_BASE + 0x24))
#define NS_ACTION_ADDR    (*(volatile uint32_t*)(NETSTREAM_BASE + 0x28))
#define NS_ACTION_DEFAULT (*(volatile uint32_t*)(NETSTREAM_BASE + 0x2C))

void tcam_write_value(uint8_t index, uint32_t w3, uint32_t w2,
                      uint32_t w1, uint32_t w0) {
    NS_TCAM_W0 = w0; NS_TCAM_W1 = w1;
    NS_TCAM_W2 = w2; NS_TCAM_W3 = w3;
    NS_TCAM_VAL_ADDR = index;
}

void tcam_write_mask(uint8_t index, uint32_t w3, uint32_t w2,
                     uint32_t w1, uint32_t w0) {
    NS_TCAM_W0 = w0; NS_TCAM_W1 = w1;
    NS_TCAM_W2 = w2; NS_TCAM_W3 = w3;
    NS_TCAM_MASK_ADDR = index;
}

void action_write(uint8_t index, uint32_t hi, uint32_t lo) {
    NS_ACTION_W0 = lo;
    NS_ACTION_W1 = hi;
    NS_ACTION_ADDR = index;
}

void action_write_default(uint32_t hi, uint32_t lo) {
    NS_ACTION_W0 = lo;
    NS_ACTION_W1 = hi;
    NS_ACTION_DEFAULT = 1;
}

void main() {

    // Configure IOs
    reg_mprj_io_0  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_1  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_2  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_3  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_4  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_5  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_6  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_7  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_8  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_9  = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_INPUT_NOPULL;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;

    // Start GPIO shift — do NOT wait, just fire and continue
    // The shift happens in background, Wishbone doesn't need it
    reg_mprj_xfer = 1;
    
    // WAIT for the shift to complete. Do NOT remove this!
    while (reg_mprj_xfer == 1);

    // Enable Wishbone immediately
    reg_wb_enable = 1;

    // Program TCAM rules
    tcam_write_value(0,
        0x00000000, 0x00000000,
        0x00000000, 0x50000020);
    tcam_write_mask(0,
        0xFFFFFFFF, 0xFFFFFFFF,
        0xFFFFFF00, 0x00FFFFDC);
    action_write(0, 0xA0000000, 0x0000002E);

    action_write_default(0x00000000, 0x00000000);

    while (1) {}
}
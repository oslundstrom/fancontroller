#include <stdint.h>
#include <stdbool.h>

// Define necessary register addresses
#define RESETS_RESET *(volatile uint32_t *) (0x4000c000)
#define PIN 14
#define IO_BANK0_GPIO25_CTRL *(volatile uint32_t *) (0x40014000 + (25 * 8) + 4)
#define IO_BANK0_GPIO_CTRL *(volatile uint32_t *) (0x40014000 + (PIN * 8) + 4)
#define IO_BANK0_GPIO0_CTRL *(volatile uint32_t *) (0x40014000 + (0 * 8) + 4)
#define SIO_GPIO_OE_SET *(volatile uint32_t *) (0xd0000024)
#define SIO_GPIO_OUT_XOR *(volatile uint32_t *) (0xd000001c)

// Main entry point
__attribute__((section(".boot2"))) void bootStage2(void)
{
    // Bring IO_BANK0 out of reset state
    RESETS_RESET &= ~(1 << 5);

    // Set GPIO function to SIO
    IO_BANK0_GPIO_CTRL = 5;

    // Set output enable for GPIO 0 in SIO
    SIO_GPIO_OE_SET |= 1 << PIN;

    while (true)
    {
        // Wait for some time
        for (uint32_t i = 0; i < 1000000; ++i);

        // Flip output for GPIO
        SIO_GPIO_OUT_XOR |= 1 << PIN;
    }
}

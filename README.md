

# Resources

[https://github.com/vxj9800/bareMetalRP2040]
[https://github.com/cpq/bare-metal-programming-guide]

## USB

[https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf#page=25]


# Log

Found out that the GPIO on RPi Pico WH is not connected to the internal gpio, but to the gpio of the wireless chip. To control that, one needs to use the SPI interface to interact with the wireless chip.
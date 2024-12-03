# Source code files
BOOT2 = boot2Blinky
COMPCRC = compCrc32
CRCVALUE = crc

# Directory to create temporary build files in
BUILDDIR = build

# Path to the SDK parts we need
SDK_PATH = pico-sdk
BASE_INCLUDE = $(SDK_PATH)/src/rp2_common/hardware_base/include
PIO_INCLUDE = $(SDK_PATH)/src/rp2_common/hardware_pio/include
GPIO_INCLUDE = $(SDK_PATH)/src/rp2_common/hardware_gpio/include
IRQ_INCLUDE = $(SDK_PATH)/src/rp2_common/hardware_irq/include
REGS_INCLUDE = $(SDK_PATH)/src/rp2040/hardware_regs/include
PICO_INCLUDE = $(SDK_PATH)/src/common/pico_base_headers/include
PICO_PLATFORM_INCLUDE = $(SDK_PATH)/src/rp2040/pico_platform/include
PICO_PLATFORM_COMPILER_INCLUDE = $(SDK_PATH)/src/rp2_common/pico_platform_compiler/include
PICO_PLATFORM_SECTIONS_INCLUDE = $(SDK_PATH)/src/rp2_common/pico_platform_sections/include
PICO_PLATFORM_PANIC_INCLUDE = $(SDK_PATH)/src/rp2_common/pico_platform_panic/include
RP2040_HW_STRUCTS_INCLUDE = $(SDK_PATH)/src/rp2040/hardware_structs/include
RP2040_HW_REGS_INCLUDE = $(SDK_PATH)/src/rp2040/hardware_regs/include
RP2350_HW_STRUCTS_INCLUDE = $(SDK_PATH)/src/rp2350/hardware_structs/include # Not really needed
RP2350_HW_REGS_INCLUDE = $(SDK_PATH)/src/rp2350/hardware_regs/include # Not really needed
BAZEL_INCLUDE = $(SDK_PATH)/bazel/include

# export RP2040 = 1

INCLUDE = include

# Compilation related variables
TOOLCHAIN = arm-none-eabi-
CFLAGS ?= -mcpu=cortex-m0plus -O3 \
		 -nostartfiles \
		 -mthumb \
		 -DPICO_RP2040=1 \
         -I$(BASE_INCLUDE) \
         -I$(PIO_INCLUDE) \
         -I$(GPIO_INCLUDE) \
         -I$(IRQ_INCLUDE) \
         -I$(REGS_INCLUDE) \
         -I$(PICO_INCLUDE) \
         -I$(PICO_PLATFORM_INCLUDE) \
         -I$(PICO_PLATFORM_COMPILER_INCLUDE) \
         -I$(PICO_PLATFORM_SECTIONS_INCLUDE) \
         -I$(PICO_PLATFORM_PANIC_INCLUDE) \
         -I$(RP2040_HW_STRUCTS_INCLUDE) \
         -I$(RP2040_HW_REGS_INCLUDE) \
         -I$(RP2350_HW_STRUCTS_INCLUDE) \
         -I$(RP2350_HW_REGS_INCLUDE) \
         -I$(BAZEL_INCLUDE) \
         -I$(INCLUDE)
LDFLAGS ?= -T link.ld -nostdlib -O3

# Utilities path
UTILS = utils

build: makeDir $(BUILDDIR)/$(BOOT2).bin $(BUILDDIR)/$(BOOT2).uf2 copyUF2

makeDir:
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/$(BOOT2).bin: $(BOOT2).c $(INCLUDE)/pico/version.h $(INCLUDE)/pico_config_platform_headers.h $(INCLUDE)/pico_config_extra_headers.h
	$(TOOLCHAIN)gcc $(CFLAGS) $(BOOT2).c -c -o $(BUILDDIR)/$(BOOT2)_temp.o
	$(TOOLCHAIN)objdump -hSD $(BUILDDIR)/$(BOOT2)_temp.o > $(BUILDDIR)/$(BOOT2)_temp.objdump
	$(TOOLCHAIN)objcopy -O binary $(BUILDDIR)/$(BOOT2)_temp.o $(BUILDDIR)/$(BOOT2)_temp.bin
	g++ -I $(UTILS) $(COMPCRC).cpp -o $(BUILDDIR)/$(COMPCRC).out
	./$(BUILDDIR)/$(COMPCRC).out $(BUILDDIR)/$(BOOT2)_temp.bin
	$(TOOLCHAIN)gcc $(BOOT2).c $(BUILDDIR)/$(CRCVALUE).c $(CFLAGS) $(LDFLAGS) -o $(BUILDDIR)/$(BOOT2).elf
	$(TOOLCHAIN)objdump -hSD $(BUILDDIR)/$(BOOT2).elf > $(BUILDDIR)/$(BOOT2).objdump
	$(TOOLCHAIN)objcopy -O binary $(BUILDDIR)/$(BOOT2).elf $@
	
%_headers.h:
	mkdir -p $(shell dirname $@)
	touch $@

$(BUILDDIR)/$(BOOT2).uf2: $(BUILDDIR)/$(BOOT2).bin
	python3 $(UTILS)/uf2/utils/uf2conv.py -b 0x10000000 -f 0xe48bff56 -c $(BUILDDIR)/$(BOOT2).bin -o $@

$(INCLUDE)/pico/version.h:
	mkdir -p $(shell dirname $@)
	python3 $(SDK_PATH)/bazel/generate_version_header.py \
		--version-string $$(git -C $(SDK_PATH) describe --tags) \
		--template $(SDK_PATH)/src/common/pico_base_headers/include/pico/version.h.in \
		> $@

copyUF2: $(BUILDDIR)/$(BOOT2).uf2
	cp $(BUILDDIR)/$(BOOT2).uf2 ./$(BOOT2).uf2

clean:
	rm -rf $(BUILDDIR) $(BOOT2).uf2

deps: | $(UTILS)/uf2 $(UTILS)/CRCpp $(SDK_PATH)

$(UTILS)/CRCpp:
	@mkdir -p $(UTILS)
	git -C $(UTILS) clone https://github.com/d-bahr/CRCpp.git

$(UTILS)/uf2:
	@mkdir -p $(UTILS)
	git -C $(UTILS) clone https://github.com/microsoft/uf2.git

$(SDK_PATH):
	git -C . clone https://github.com/raspberrypi/pico-sdk.git

setup: deps
	sudo apt update
	sudo apt install make gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential g++ libstdc++-arm-none-eabi-newlib

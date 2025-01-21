# Source code files
BOOT2 = boot2Blinky
COMPCRC = compCrc32
CRCVALUE = crc

# Directory to create temporary build files in
BUILDDIR = build

# Compilation related variables
TOOLCHAIN = arm-none-eabi-
CFLAGS ?= -mcpu=cortex-m0plus -O3
LDFLAGS ?= -T link.ld -nostdlib -O3

# Utilities path
UTILS = utils

build: makeDir $(BUILDDIR)/$(BOOT2).bin $(BUILDDIR)/$(BOOT2).uf2 copyUF2

makeDir:
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/$(BOOT2).bin: $(BOOT2).c | $(UTILS)/uf2 $(UTILS)/CRCpp
	$(TOOLCHAIN)gcc $(CFLAGS) $(BOOT2).c -c -o $(BUILDDIR)/$(BOOT2)_temp.o
	$(TOOLCHAIN)objdump -hSD $(BUILDDIR)/$(BOOT2)_temp.o > $(BUILDDIR)/$(BOOT2)_temp.objdump
	$(TOOLCHAIN)objcopy -O binary $(BUILDDIR)/$(BOOT2)_temp.o $(BUILDDIR)/$(BOOT2)_temp.bin
	g++ -I $(UTILS) $(COMPCRC).cpp -o $(BUILDDIR)/$(COMPCRC).out
	./$(BUILDDIR)/$(COMPCRC).out $(BUILDDIR)/$(BOOT2)_temp.bin
	$(TOOLCHAIN)gcc $(BOOT2).c $(BUILDDIR)/$(CRCVALUE).c $(CFLAGS) $(LDFLAGS) -o $(BUILDDIR)/$(BOOT2).elf
	$(TOOLCHAIN)objdump -hSD $(BUILDDIR)/$(BOOT2).elf > $(BUILDDIR)/$(BOOT2).objdump
	$(TOOLCHAIN)objcopy -O binary $(BUILDDIR)/$(BOOT2).elf $@

$(BUILDDIR)/$(BOOT2).uf2: $(BUILDDIR)/$(BOOT2).bin
	python3 $(UTILS)/uf2/utils/uf2conv.py -b 0x10000000 -f 0xe48bff56 -c $(BUILDDIR)/$(BOOT2).bin -o $@

copyUF2: $(BUILDDIR)/$(BOOT2).uf2
	cp $(BUILDDIR)/$(BOOT2).uf2 ./$(BOOT2).uf2

deploy: build
	sudo openocd -f ../openocd/tcl/interface/cmsis-dap.cfg -f ../openocd/tcl/target/rp2040.cfg -c "adapter speed 5000" -c "program $(BUILDDIR)/$(BOOT2).elf"

mostlyclean:
	rm -rf $(BUILDDIR) $(BOOT2).uf2

clean: mostlyclean
	rm -rf $(UTILS)/uf2 $(UTILS)/CRCpp

deps: | $(UTILS)/uf2 $(UTILS)/CRCpp

$(UTILS)/CRCpp:
	@mkdir -p $(UTILS)
	git -C $(UTILS) clone https://github.com/d-bahr/CRCpp.git

$(UTILS)/uf2:
	@mkdir -p $(UTILS)
	git -C $(UTILS) clone https://github.com/microsoft/uf2.git

setup: deps
	sudo apt update
	sudo apt install make gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential g++ libstdc++-arm-none-eabi-newlib

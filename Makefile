.PHONY: setup all

all: boot2Blinky_temp.bin boot2Blinky.bin
	
boot2Blinky.uf2:
	python3 ./uf2/utils/uf2conv.py -b 0x10000000 -f 0xe48bff56 -c boot2Blinky.bin -o boot2Blinky.uf2
	
boot2Blinky.bin: boot2Blinky.elf
	arm-none-eabi-objcopy -O binary boot2Blinky.elf boot2Blinky.bin

boot2Blinky.elf: link.ld boot2Blinky.c crc.c
	arm-none-eabi-gcc boot2Blinky.c crc.c -mcpu=cortex-m0plus -T link.ld -nostdlib -o boot2Blinky.elf

boot2Blinky_temp.o: boot2Blinky.c
	arm-none-eabi-gcc boot2Blinky.c -mcpu=cortex-m0plus -c -o boot2Blinky_temp.o
	
boot2Blinky_temp.elf: boot2Blinky_temp.o link.ld
	arm-none-eabi-ld boot2Blinky_temp.o -T link_temp.ld -nostdlib -o boot2Blinky_temp.elf

boot2Blinky_temp.bin: boot2Blinky_temp.elf
	arm-none-eabi-objcopy -O binary boot2Blinky_temp.elf boot2Blinky_temp.bin

crc.c: compCrc32.out boot2Blinky_temp.bin
	./compCrc32.out boot2Blinky_temp.bin

compCrc32.out:
	g++ compCrc32.cpp -o compCrc32.out

deps: | uf2 $ CRCpp

CRCpp:
	git clone https://github.com/d-bahr/CRCpp.git

uf2:
	git clone https://github.com/microsoft/uf2.git

setup:
	sudo apt update
	sudo apt install make gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential g++ libstdc++-arm-none-eabi-newlib

# Makefile - build firmware update utility/disk.
#
#  Copyright (c) 2023 Thorsten C. Brehm
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.

include ../../version.mk

ARDUINO_HEX_FILE      := ../../Apple2Arduino/Apple2Arduino.ino.with_bootloader.hex

all: bin/FWUPDATE.SYSTEM

# build ProDOS executable
bin/FWUPDATE.SYSTEM: bin/fwupdate.o bin/dan2stk500.o
	@echo "Linking $@"
	@ld65 -C apple2-system.cfg  -D __EXEHDR__=0 -vm -m bin/FWUPDATE.list -o $@ bin/fwupdate.o bin/dan2stk500.o apple2.lib

# build firmware update module
bin/fwupdate.o: fwupdate.c ../../version.mk
	@echo "Compiling fwupdate.c"
	@cc65 -t apple2 -D__EXEHDR__=0 -DFW_VERSION=\"$(FW_VERSION)\" -o bin/fwupdate.asm fwupdate.c
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ bin/fwupdate.asm

# build STK500 updater
bin/dan2stk500.o: dan2stk500.asm bin/fwimage.bin
	@echo "Assembling dan2stk500.asm"
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ $<

# generate include file with content of Arduino hex file
bin/fwimage.bin: $(ARDUINO_HEX_FILE) bin
	@echo "Converting Arduino firmware hex to binary"
	@python3 hex2bin.py --size 32768 --fillbyte 255 $(ARDUINO_HEX_FILE) bin/fwimage.bin

bin:
	- mkdir bin

clean:
	@echo "Clean up..."
	@rm -f bin/*


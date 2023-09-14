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

# build for ATMEGA "328P" or "644P"? (select by calling 'make ATMEGA=328P' or 'make ATMEGA=644P')
ATMEGA ?= 328P

ifeq ($(strip $(ATMEGA)),328P)
BINDIR           := bin-328p
# maximum firmware size: 32256 bytes (32K-512, since the last 512 bytes belong to the bootloader, which we cannot touch)
FW_MAX_SIZE      := 32256
ARDUINO_HEX_FILE := ../../Apple2Arduino/Apple2Arduino.ino.328p.with_bootloader.hex
endif

ifeq ($(strip $(ATMEGA)),644P)
BINDIR           := bin-644p
# maximum firmware size: 32768 bytes (32K, actual flash of 644P is larger, but this will do for now, and disk/RAM space is limited)
FW_MAX_SIZE      := 32768
ARDUINO_HEX_FILE := ../../Apple2Arduino/Apple2Arduino.ino.644p.with_bootloader.hex
endif

ifeq ($(ARDUINO_HEX_FILE),)
  DUMMY := $(error ERROR: Unknown DAN][ hardware type: '$(ATMEGA)'. Currently supported types: '328P' or '644P'.)
endif

# select binary directory
# provide a define to CC65/CA65 selecting the ATMEGA328P vs ATMEGA644P
DEFINES := -D__EXEHDR__=0 -DATMEGA$(ATMEGA)=1

all: $(BINDIR) $(BINDIR)/FWUPDATE.SYSTEM

# build ProDOS executable
$(BINDIR)/FWUPDATE.SYSTEM: $(BINDIR)/fwupdate.o $(BINDIR)/dan2stk500.o
	@echo "Linking $@"
	@ld65 -C apple2-system.cfg $(DEFINES) -vm -m $(BINDIR)/FWUPDATE.list -o $@ $(BINDIR)/fwupdate.o $(BINDIR)/dan2stk500.o apple2.lib

# build firmware update module
$(BINDIR)/fwupdate.o: fwupdate.c ../../version.mk
	@echo "Compiling fwupdate.c"
	@cc65 -t apple2 $(DEFINES) -DFW_VERSION=\"$(FW_VERSION)\" -o $(BINDIR)/fwupdate.asm fwupdate.c
	@ca65 -t apple2 $(DEFINES) -o $@ $(BINDIR)/fwupdate.asm

# build STK500 updater
$(BINDIR)/dan2stk500.o: dan2stk500.asm $(BINDIR)/fwimage.bin
	@echo "Assembling dan2stk500.asm"
	@ca65 -t apple2 $(DEFINES) -o $@ $<

# generate include file with content of Arduino hex file
$(BINDIR)/fwimage.bin: $(ARDUINO_HEX_FILE) $(BINDIR)
	@echo "Converting Arduino firmware hex to binary"
	@python3 hex2bin.py --size $(FW_MAX_SIZE) --fillbyte 255 $(ARDUINO_HEX_FILE) $@

$(BINDIR):
	- mkdir $(BINDIR)

clean:
	@echo "Clean up..."
	@rm -f bin-*/*


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

FW_MAJOR := $(word 1,$(subst ., ,$(FW_VERSION)))
FW_MINOR := $(word 2,$(subst ., ,$(FW_VERSION)))
FW_MAINT := $(word 3,$(subst ., ,$(FW_VERSION)))

VERSION_INFO := -DFW_MAJOR=$(FW_MAJOR) -DFW_MINOR=$(FW_MINOR) -DFW_MAINT=$(FW_MAINT)

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

APPLEII_EXECUTABLE  := $(BINDIR)/APPLEII_FWUPDATE.SYSTEM
APPLEIII_EXECUTABLE := $(BINDIR)/APPLEIII_FWUPDATE.SOS

# select binary directory
# provide a define to CC65/CA65 selecting the ATMEGA328P vs ATMEGA644P
DEFINES := -D__EXEHDR__=0 -DATMEGA$(ATMEGA)=1 $(VERSION_INFO)

DEPENDENCIES := AppleROM.inc Makefile ../../version.mk

all: $(BINDIR) $(APPLEII_EXECUTABLE) $(APPLEIII_EXECUTABLE)

###############################################################################
# APPLE II: ProDOS executable
###############################################################################

# APPLE II: build ProDOS executable
$(APPLEII_EXECUTABLE): $(BINDIR)/APPLEII_startup.o $(BINDIR)/APPLEII_fwupdate.o $(BINDIR)/APPLEII_dan2stk500.o
	@echo "APPLE II: Linking $@"
	@ld65 -C apple2-system.cfg $(DEFINES) -vm -m $@.list -o $@ $^

# APPLE II: build APPLE II startup
$(BINDIR)/APPLEII_startup.o: APPLEII_startup.asm $(DEPENDENCIES)
	@echo "APPLE II: Assembling APPLEII_startup.asm"
	@ca65 -t apple2 $(DEFINES) --listing $(@:.o=.lst) -o $@ $<

# APPLE II: build main update utility
$(BINDIR)/APPLEII_fwupdate.o: fwupdate.asm $(BINDIR)/fwimage.bin $(DEPENDENCIES)
	@echo "APPLE II: Assembling fwupdate.asm"
	@ca65 $(DEFINES) --listing $(@:.o=.lst) -o $@ $<

# APPLE II: build STK500 updater
$(BINDIR)/APPLEII_dan2stk500.o: dan2stk500.asm $(BINDIR)/fwimage.bin $(DEPENDENCIES)
	@echo "APPLE II: Assembling dan2stk500.asm"
	@ca65 -t apple2 $(DEFINES) -o $@ $<


###############################################################################
# APPLE III: SOS executable
###############################################################################

# APPLE III: build executable
$(APPLEIII_EXECUTABLE): $(BINDIR)/APPLEIII_startup.o $(BINDIR)/APPLEIII_fwupdate.o $(BINDIR)/APPLEIII_dan2stk500.o
	@echo "APPLE III: Linking $@"
	@ld65 -C apple3sos.cfg -S 0x1ff2 $(DEFINES) -DAPPLE3=1 -vm -m $@.list -o $@ $^
	@da65 -S 0x1ff2 -vvvvvv $(APPLEIII_EXECUTABLE) > $(APPLEIII_EXECUTABLE).dump

# APPLE III: build APPLE III startup
$(BINDIR)/APPLEIII_startup.o: APPLEIII_startup.asm $(DEPENDENCIES)
	@echo "APPLE III: Assembling APPLEII_startup.asm"
	@ca65 $(DEFINES) -DAPPLE3=1 --listing $(@:.o=.lst) -o $@ $<

# APPLE III: build main update utility
$(BINDIR)/APPLEIII_fwupdate.o: fwupdate.asm $(DEPENDENCIES)
	@echo "APPLE III: Assembling fwupdate.asm"
	@ca65 $(DEFINES) -DAPPLE3=1 --listing $(@:.o=.lst) -o $@ $<

# APPLE III: build STK500 updater
$(BINDIR)/APPLEIII_dan2stk500.o: dan2stk500.asm $(BINDIR)/fwimage.bin $(DEPENDENCIES)
	@echo "APPLE III: Assembling dan2stk500.asm"
	@ca65 $(DEFINES) -DAPPLE3=1 --listing $(@:.o=.lst) -o $@ $<


###############################################################################
# Common: hex file processing
###############################################################################

# generate include file with content of Arduino hex file
$(BINDIR)/fwimage.bin: $(ARDUINO_HEX_FILE) $(BINDIR)
	@echo "Converting Arduino firmware hex to binary"
	@python3 hex2bin.py --size $(FW_MAX_SIZE) --fillbyte 255 $(ARDUINO_HEX_FILE) $@

$(BINDIR):
	- mkdir $(BINDIR)

clean:
	@echo "Clean up..."
	@rm -f bin-*/*


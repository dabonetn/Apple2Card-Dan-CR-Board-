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

include version.mk

ZIP_FILE := DANII_Release_v$(FW_VERSION).zip

DISK_FILES := $(APPLE2_DISK_NAME).po $(APPLE2_DISK_NAME).dsk ip65.po ip65.dsk ADTPRO-2.1.D2.PO ADTPRO-2.1.D2.DSK \
              VOLxx_$(APPLE3_DISK_NAME).po FLOPPY_$(APPLE3_DISK_NAME).po readme.txt

HEX_FILE := Apple2Arduino/Apple2Arduino.ino.328p.with_bootloader.hex
UTILS    := $(addprefix utilities/,allvols/bin/ALLVOLS.SYSTEM \
                        eeprom/bin/EEPROM.PROG.SYS \
                        eeprom/bin/SRAM.PROG.SYS)

# build for ATMEGA "328P" or "644P"? (select by calling 'make ATMEGA=328P' or 'make ATMEGA=644P')
ATMEGA ?= 328P

.PHONY: build all common clean release ftp build 328P 644P

# build board which is selected by ATMEGA=... switch (328P by default)
build: common
	make -C Apple2Arduino ATMEGA=$(ATMEGA)
	make -C utilities ATMEGA=$(ATMEGA)

# build common stuff once (things not dependent on ATMEGA type)
common:
	make -C eprom
	make -C bootpg

# build ATMEGA328P board binaries
328P: common
	make -C Apple2Arduino ATMEGA=328P
	make -C utilities ATMEGA=328P

# build ATMEGA644P board binaries
644P: common
	make -C Apple2Arduino ATMEGA=644P
	make -C utilities ATMEGA=644P

# build everything - for all supported types
all: 328P 644P

# clean everything
clean:
	make -C bootpg $@
	make -C eprom $@
	make -C Apple2Arduino $@ ATMEGA=328P
	make -C Apple2Arduino $@ ATMEGA=644P
	make -C utilities $@ ATMEGA=328P
	make -C utilities $@ ATMEGA=644P

release:
	- rm -f $(ZIP_FILE)
	@zip $(ZIP_FILE) eprom/bin/eprom.bin $(addprefix dsk/,$(DISK_FILES)) $(HEX_FILE) $(UTILS)

ftp:
	make -C utilities $@ ATMEGA=$(ATMEGA)


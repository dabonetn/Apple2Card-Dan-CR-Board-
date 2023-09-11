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

DISK_FILES := $(DISK_NAME).po $(DISK_NAME).dsk ip65.po ip65.dsk ADTPRO-2.1.D2.PO ADTPRO-2.1.D2.DSK

HEX_FILE := Apple2Arduino/Apple2Arduino.ino.with_bootloader.hex
UTILS    := $(addprefix utilities/,allvols/bin/ALLVOLS.SYSTEM ipconfig/bin/IPCONFIG.SYSTEM fwupdate/bin/FWUPDATE.SYSTEM eeprom/bin/EEPROM.PROG.SYS eeprom/bin/SRAM.PROG.SYS)

all:
	make -C bootpg $@
	make -C eprom $@
	make -C Apple2Arduino $@
	make -C utilities $@

clean:
	make -C bootpg $@
	make -C eprom $@
	make -C Apple2Arduino $@
	make -C utilities $@

release:
	- rm -f $(ZIP_FILE)
	@zip $(ZIP_FILE) eprom/bin/eprom.bin $(addprefix dsk/,$(DISK_FILES)) $(HEX_FILE) $(UTILS)

ftp:
	make -C utilities $@


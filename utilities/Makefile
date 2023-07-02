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

# AppleCommander
AC := java -jar ../bootpg/tools/AppleCommander-1.3.5.13-ac.jar

include ../version.mk
FW_VERSION := $(subst ",,$(FW_VERSION))

# target disk image
DISK_IMAGE_NAME := bin/DANIIUTIL.$(FW_VERSION)

# for direct FTP download: adapt to your needs
DAN2_FTP_IP := 192.168.4.65
DAN2_VOL_IMAGE := /sd1/BLKDEV0D.PO

TARGETS := all clean

all: bin
	make -C eeprom $@
	make -C fwupdate $@
	make -C ipconfig $@
	make -C allvols $@
	make $(DISK_IMAGE_NAME).po

clean:
	make -C eeprom $@
	make -C fwupdate $@
	make -C ipconfig $@
	make -C allvols $@
	- rm -f bin/*

bin:
	- mkdir bin

# build ProDOS disk image
$(DISK_IMAGE_NAME).po: Makefile ../version.mk fwupdate/bin/FWUPDATE.SYSTEM eeprom/bin/EEPROM.PROG.SYS allvols/bin/ALLVOLS.SYSTEM ipconfig/bin/IPCONFIG.SYSTEM
	@echo "Building volume $@"
	@cp ipconfig/ProDOS_312.dsk $(DISK_IMAGE_NAME).dsk
	@$(AC) -g $(DISK_IMAGE_NAME).dsk MANAGER.SYS bin/MANAGER.SYS
	@$(AC) -g $(DISK_IMAGE_NAME).dsk FORMAT.SYS bin/FORMAT.SYS
	@$(AC) -d $(DISK_IMAGE_NAME).dsk MANAGER.SYS
	@$(AC) -d $(DISK_IMAGE_NAME).dsk FORMAT.SYS
	@$(AC) -d $(DISK_IMAGE_NAME).dsk QUIT.SYSTEM
	@$(AC) -d $(DISK_IMAGE_NAME).dsk PRO.DATE
	@$(AC) -n $(DISK_IMAGE_NAME).dsk DANIIUTIL.$(FW_VERSION)
	@cat bin/MANAGER.SYS | $(AC) -p $(DISK_IMAGE_NAME).dsk MANAGER.SYS sys
	@cat bin/FORMAT.SYS | $(AC) -p $(DISK_IMAGE_NAME).dsk FORMAT.SYS sys
	@cat fwupdate/bin/FWUPDATE.SYSTEM | $(AC) -p $(DISK_IMAGE_NAME).dsk FWUPDATE.SYSTEM sys
	@cat eeprom/bin/EEPROM.PROG.SYS   | $(AC) -p $(DISK_IMAGE_NAME).dsk EEPROM.SYS sys
	@cat allvols/bin/ALLVOLS.SYSTEM   | $(AC) -p $(DISK_IMAGE_NAME).dsk ALLVOLS.SYS sys
	@cat ipconfig/bin/IPCONFIG.SYSTEM | $(AC) -p $(DISK_IMAGE_NAME).dsk IPCONFIG.SYS sys
	@echo "Converting to ProDOS..."
	@python3 ipconfig/dsk2po.py $(DISK_IMAGE_NAME).dsk
	@cp $(DISK_IMAGE_NAME).dsk ../dsk/.
	@cp $@ ../dsk/.

list: $(DISK_IMAGE_NAME).po
	@$(AC) -l $(DISK_IMAGE_NAME).po

# for testing: ftp upload of ProDOS image to an DAN][ controller's SD volume
ftp: $(DISK_IMAGE_NAME).po
	@echo "FTP transfer..."
	ftp -u apple2@$(DAN2_FTP_IP):$(DAN2_VOL_IMAGE) $(DISK_IMAGE_NAME).po


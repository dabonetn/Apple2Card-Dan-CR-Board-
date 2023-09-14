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

# optional local file with user environment (i.e. path to Arduino build utilities)
-include ../localsettings.mk

# For direct FTP download: IP address and volume file for testing
# => Set these option in your local "../localsettings.mk" to match your test setup.
# DAN2_FTP_IP    := 192.168.4.65
# DAN2_VOL_IMAGE := /sd1/VOL0D.PO

DSK_FILE := bin/$(DISK_NAME).dsk

ATMEGA ?= 328P

# optionally include both 328P/644P updaters in the tools disk
FWUPDATER_328P := fwupdate/bin-328p/FWUPDATE.SYSTEM
FWUPDATER_644P := fwupdate/bin-644p/FWUPDATE.SYSTEM

ifneq ($(ATMEGA),328P)
ifeq (,$(wildcard fwupdate/bin-328p/FWUPDATE.SYSTEM))
# When building *644P* and the 328P updater does *not* exist, then don't include it in the disk image.
FWUPDATER_328P :=
endif
endif

ifneq ($(ATMEGA),644P)
ifeq (,$(wildcard fwupdate/bin-644p/FWUPDATE.SYSTEM))
# When building *328P* and the 644P updater does *not* exist, then don't include it in the disk image.
FWUPDATER_644P :=
endif
endif

TARGETS := all clean

all: bin
	make -C eeprom $@
	make -C fwupdate $@ ATMEGA=$(ATMEGA)
	make -C ipconfig $@
	make -C allvols $@
	make bin/$(DISK_NAME).po

clean:
	make -C eeprom $@
	make -C fwupdate $@
	make -C ipconfig $@
	make -C allvols $@
	- rm -f bin/*

bin:
	- mkdir bin

# build ProDOS disk image
bin/$(DISK_NAME).po: Makefile ../version.mk $(FWUPDATER_328P) $(FWUPDATER_644P) eeprom/bin/EEPROM.PROG.SYS allvols/bin/ALLVOLS.SYSTEM ipconfig/bin/IPCONFIG.SYSTEM
	@echo "Building volume $@"
	@cp ipconfig/ProDOS_312.dsk $(DSK_FILE)
	@$(AC) -g $(DSK_FILE) MANAGER.SYS bin/MANAGER.SYS
	@$(AC) -g $(DSK_FILE) FORMAT.SYS  bin/FORMAT.SYS
	@$(AC) -d $(DSK_FILE) MANAGER.SYS
	@$(AC) -d $(DSK_FILE) FORMAT.SYS
	@$(AC) -d $(DSK_FILE) QUIT.SYSTEM
	@$(AC) -d $(DSK_FILE) PRO.DATE
	@$(AC) -n $(DSK_FILE) $(DISK_NAME)
	@cat bin/MANAGER.SYS              | $(AC) -p $(DSK_FILE) MANAGER.SYS     sys
	@cat bin/FORMAT.SYS               | $(AC) -p $(DSK_FILE) FORMAT.SYS      sys
ifneq (,$(FWUPDATER_328P))
	@echo "Adding ATMEGA328P firmware updater..."
# we currently launch the 328P updater automatically. Hence, it has the ".system" suffix.
	@cat $(FWUPDATER_328P)            | $(AC) -p $(DSK_FILE) FWUPD328.SYSTEM sys
endif
ifneq (,$(FWUPDATER_644P))
	@echo "Adding ATMEGA644P firmware updater..."
# Currently the 644P updater is added as an extra to the disk. Needs to be launched manually.
	@cat $(FWUPDATER_644P)            | $(AC) -p $(DSK_FILE) FWUPD644.SYS    sys
endif
	@cat eeprom/bin/EEPROM.PROG.SYS   | $(AC) -p $(DSK_FILE) EEPROM.SYS      sys
	@cat allvols/bin/ALLVOLS.SYSTEM   | $(AC) -p $(DSK_FILE) ALLVOLS.SYS     sys
	@cat ipconfig/bin/IPCONFIG.SYSTEM | $(AC) -p $(DSK_FILE) IPCONFIG.SYS    sys
	@echo "Converting to ProDOS..."
	@python3 ipconfig/dsk2po.py $(DSK_FILE)
	@cp $(DSK_FILE) ../dsk/.
	@cp $@ ../dsk/.

list: bin/$(DISK_NAME).po
	@$(AC) -l $<

# for testing: ftp upload of ProDOS image to an DAN][ controller's SD volume
ftp: bin/$(DISK_NAME).po
	@echo "FTP transfer..."
	ftp -u apple2@$(DAN2_FTP_IP):$(DAN2_VOL_IMAGE) $<


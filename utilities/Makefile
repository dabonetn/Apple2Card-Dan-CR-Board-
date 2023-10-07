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

APPLE2_DSK_FILE := bin/$(APPLE2_DISK_NAME).dsk

# Alternate firmware updater for Apple III (native SOS).
APPLE3_FLOPPY_TEMPLATE := templates/APPLEIII_SOS_FLOPPY_MASTER.po
APPLE3_FLOPPY_DISK     := bin/FLOPPY_$(APPLE3_DISK_NAME).po
APPLE3_DAN2VOL_TEMPLATE:= templates/APPLEIII_DAN2VOL_MASTER.po
APPLE3_DAN2VOLUME      := bin/VOLxx_$(APPLE3_DISK_NAME).po

ATMEGA ?= 328P

# optionally include both 328P/644P updaters in the tools disk
APPLE2_FWUPDATER_328P := fwupdate/bin-328p/APPLEII_FWUPDATE.SYSTEM
APPLE2_FWUPDATER_644P := fwupdate/bin-644p/APPLEII_FWUPDATE.SYSTEM

APPLE3_FWUPDATER_328P := fwupdate/bin-328p/APPLEIII_FWUPDATE.SOS
APPLE3_FWUPDATER_644P := fwupdate/bin-644p/APPLEIII_FWUPDATE.SOS

ifneq ($(ATMEGA),328P)
ifeq (,$(wildcard $(APPLE2_FWUPDATER_328P)))
# When building *644P* and the 328P updater does *not* exist, then don't include it in the disk image.
APPLE2_FWUPDATER_328P :=
APPLE3_FWUPDATER_328P :=
endif
endif

ifneq ($(ATMEGA),644P)
ifeq (,$(wildcard $(APPLE2_FWUPDATER_644P)))
# When building *328P* and the 644P updater does *not* exist, then don't include it in the disk image.
APPLE2_FWUPDATER_644P :=
APPLE3_FWUPDATER_644P :=
endif
endif

TARGETS := all clean

all: bin
	make -C eeprom $@
	make -C fwupdate $@ ATMEGA=$(ATMEGA)
	make -C ipconfig $@
	make -C allvols $@
	make $(APPLE2_DSK_FILE)
	make $(APPLE3_FLOPPY_DISK)
	make $(APPLE3_DAN2VOLUME)

clean:
	make -C eeprom $@
	make -C fwupdate $@
	make -C ipconfig $@
	make -C allvols $@
	- rm -f bin/*

bin:
	- mkdir bin

###############################################################################
# APPLE II: ProDOS volumes
###############################################################################

# build ProDOS disk image
$(APPLE2_DSK_FILE): Makefile ../version.mk $(APPLE2_FWUPDATER_328P) $(APPLE2_FWUPDATER_644P) eeprom/bin/EEPROM.PROG.SYS allvols/bin/ALLVOLS.SYSTEM ipconfig/bin/IPCONFIG.SYSTEM
	@echo "Building volume $@"
	@cp ipconfig/ProDOS_312.dsk $@_
	@$(AC) -g $@_ MANAGER.SYS bin/MANAGER.SYS
	@$(AC) -g $@_ FORMAT.SYS  bin/FORMAT.SYS
	@$(AC) -d $@_ MANAGER.SYS
	@$(AC) -d $@_ FORMAT.SYS
	@$(AC) -d $@_ QUIT.SYSTEM
	@$(AC) -d $@_ PRO.DATE
	@$(AC) -n $@_ $(APPLE2_DISK_NAME)
	@cat bin/MANAGER.SYS              | $(AC) -p $@_ MANAGER.SYS     sys
	@cat bin/FORMAT.SYS               | $(AC) -p $@_ FORMAT.SYS      sys
ifneq (,$(APPLE2_FWUPDATER_328P))
	@echo "Adding ATMEGA328P firmware updater..."
# we currently launch the 328P updater automatically. Hence, it has the ".system" suffix.
	@cat $(APPLE2_FWUPDATER_328P)     | $(AC) -p $@_ FWUPD328.SYSTEM sys
endif
ifneq (,$(APPLE2_FWUPDATER_644P))
	@echo "Adding ATMEGA644P firmware updater..."
# Currently the 644P updater is added as an extra to the disk. Needs to be launched manually.
	@cat $(APPLE2_FWUPDATER_644P)     | $(AC) -p $@_ FWUPD644.SYS    sys
endif
	@cat eeprom/bin/EEPROM.PROG.SYS   | $(AC) -p $@_ EEPROM.SYS      sys
	@cat allvols/bin/ALLVOLS.SYSTEM   | $(AC) -p $@_ ALLVOLS.SYS     sys
	@cat ipconfig/bin/IPCONFIG.SYSTEM | $(AC) -p $@_ IPCONFIG.SYS    sys
	@mv $@_ $@
	@echo "Converting to ProDOS..."
	@python3 ipconfig/dsk2po.py $@
	@cp $(APPLE2_DSK_FILE) ../dsk/.
	@cp $@ ../dsk/.

list: bin/$(APPLE2_DISK_NAME).po
	@$(AC) -l $<

###############################################################################
# APPLE III: SOS volumes
###############################################################################

$(APPLE3_FLOPPY_DISK): Makefile ../version.mk $(APPLE3_FWUPDATER_328P) $(APPLE3_FWUPDATER_644P) $(APPLE3_FLOPPY_TEMPLATE)
	@cp $(APPLE3_FLOPPY_TEMPLATE) $@_
	@$(AC) -n $@_ A3DAN2FW.$(FW_VERSION)
ifneq (,$(APPLE3_FWUPDATER_328P))
	@echo "Adding ATMEGA328P firmware updater..."
	@cat $(APPLE3_FWUPDATER_328P) | $(AC) -p $@_ SOS.INTERP SOS
endif
ifneq (,$(APPLE3_FWUPDATER_644P))
	@echo "Adding ATMEGA644P firmware updater..."
	@cat $(APPLE3_FWUPDATER_644P) | $(AC) -p $@_ DAN2FWUPDATE.644 SOS
endif
	@mv $@_ $@
	@cp $@ ../dsk/.
	@$(AC) -l $@

$(APPLE3_DAN2VOLUME): Makefile ../version.mk $(APPLE3_FWUPDATER_328P) $(APPLE3_FWUPDATER_644P) $(APPLE3_DAN2VOL_TEMPLATE)
	@cp $(APPLE3_DAN2VOL_TEMPLATE) $@_
	@$(AC) -n $@_ A3DAN2FW.$(FW_VERSION)
ifneq (,$(APPLE3_FWUPDATER_328P))
	@echo "Adding ATMEGA328P firmware updater..."
	@cat $(APPLE3_FWUPDATER_328P) | $(AC) -p $@_ SOS.INTERP SOS
endif
ifneq (,$(APPLE3_FWUPDATER_644P))
	@echo "Adding ATMEGA644P firmware updater..."
	@cat $(APPLE3_FWUPDATER_644P) | $(AC) -p $@_ DAN2FWUPDATE.644 SOS
endif
	@mv $@_ $@
	@cp $@ ../dsk/.
	@$(AC) -l $@

# for testing: ftp upload of volume image to a DAN][ controller's SD
ftp: a2ftp

# Apple II
a2ftp: $(APPLE2_DSK_FILE:.dsk=.po)
	@echo "FTP transfer to Apple II..."
	ftp -u dan@$(APPLE2_DAN2_FTP_IP):$(APPLE2_DAN2_VOL_IMAGE) $<

# Apple III
a3ftp: $(APPLE3_DAN2VOLUME)
	@echo "FTP transfer to Apple III..."
	ftp -u dan@$(APPLE3_DAN2_FTP_IP):$(APPLE3_DAN2_VOL_IMAGE) $<


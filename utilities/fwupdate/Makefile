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
AC := java -jar ../../bootpg/tools/AppleCommander-1.3.5.13-ac.jar

include ../../version.mk
FW_VERSION := $(subst ",,$(FW_VERSION))

# target disk image
DISK_IMAGE_NAME := bin/DANII_FW_$(FW_VERSION)

# for direct FTP download: adapt to your needs
DAN2_FTP_IP := 192.168.4.65
DAN2_VOL_IMAGE := /sd1/BLKDEV0C.PO

ARDUINO_HEX_FILE      := ../../Apple2Arduino/Apple2Arduino.ino.with_bootloader.hex

all: $(DISK_IMAGE_NAME).po

# build ProDOS disk image
$(DISK_IMAGE_NAME).po: bin/FWUPDATE.PRG Makefile ../../version.mk
	@echo "Building volume $@"
	@cp ../ipconfig/ProDOS_312.dsk $(DISK_IMAGE_NAME).dsk
	@$(AC) -d $(DISK_IMAGE_NAME).dsk QUIT.SYSTEM
	@$(AC) -n $(DISK_IMAGE_NAME).dsk DANII.FW.$(FW_VERSION)
	@cat bin/FWUPDATE.PRG | $(AC) -p $(DISK_IMAGE_NAME).dsk DAN.FWUP.SYSTEM sys
	@cat ../eeprom/bin/EEPROM.SYSTEM | $(AC) -p $(DISK_IMAGE_NAME).dsk EEPROM.SYSTEM sys
	@echo "Converting to ProDOS..."
	@python3 ../ipconfig/dsk2po.py $(DISK_IMAGE_NAME).dsk
	@cp $(DISK_IMAGE_NAME).dsk ../../dsk/.
	@cp $@ ../../dsk/.

# build ProDOS executable
bin/FWUPDATE.PRG: bin/fwupdate.o bin/dan2stk500.o
	@echo "Linking $@"
	@ld65 -C apple2-system.cfg  -D __EXEHDR__=0 -vm -m bin/FWUPDATE.list -o $@ bin/fwupdate.o bin/dan2stk500.o apple2.lib

# build firmware update module
bin/fwupdate.o: fwupdate.c bin/fw.h
	@echo "Compiling fwupdate.c"
	@cc65 -t apple2 -D__EXEHDR__=0 -o bin/fwupdate.asm fwupdate.c
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ bin/fwupdate.asm

# build STK500 updater
bin/dan2stk500.o: dan2stk500.asm
	@echo "Assembling dan2stk500.asm"
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ $<

# generate include file with content of Arduino hex file
bin/fw.h: $(ARDUINO_HEX_FILE) bin
	@echo "Converting Arduino firmware hex to binary"
	@python3 hex2bin.py --size 32768 --fillbyte 255 $(ARDUINO_HEX_FILE) bin/fwimage.bin
	@echo "Converting firmware binary to header file"
	@python3 ../../bootpg/tools/file2header.py --binary --file bin/fwimage.bin > $@

bin:
	- mkdir bin

clean:
	@echo "Clean up..."
	@rm -f bin/*

# for testing: ftp upload of ProDOS image to an DAN][ controller's SD volume
ftp: $(DISK_IMAGE_NAME).po
	@echo "FTP transfer..."
	ftp -u apple2@$(DAN2_FTP_IP):$(DAN2_VOL_IMAGE) $(DISK_IMAGE_NAME).po


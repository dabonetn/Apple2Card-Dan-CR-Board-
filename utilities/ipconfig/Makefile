# Makefile - build FTP/IP configuration utility/disk.
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

# target disk image
DISK_IMAGE_NAME := bin/DANII_FTP_IPCONFIG

# for direct FTP download: adapt to your needs
DAN2_FTP_IP := 192.168.4.65
DAN2_VOL_IMAGE := /sd1/BLKDEV0E.PO

all: $(DISK_IMAGE_NAME).po

# build ProDOS disk image
$(DISK_IMAGE_NAME).po: bin/IPCONFIG.PRG
	@echo "Building volume DANII.IPCONFIG"
	@cp ProDOS_312.dsk $(DISK_IMAGE_NAME).dsk
	@$(AC) -d $(DISK_IMAGE_NAME).dsk QUIT.SYSTEM
	@$(AC) -n $(DISK_IMAGE_NAME).dsk DANII.IPCONFIG
	@cat bin/IPCONFIG.PRG | $(AC) -p $(DISK_IMAGE_NAME).dsk IPCONFIG.SYSTEM sys
	@echo "Converting to ProDOS..."
	@python3 dsk2po.py $(DISK_IMAGE_NAME).dsk
	@cp $(DISK_IMAGE_NAME).dsk ../../dsk/.
	@cp $@ ../../dsk/.

# build ProDOS executable
bin/IPCONFIG.PRG: bin/IPCONFIG.o bin/dan2if.o
	@echo "Linking $@"
	@ld65 -C apple2-system.cfg  -D __EXEHDR__=0 -m bin/IPCONFIG.list -o $@ bin/IPCONFIG.o bin/dan2if.o apple2.lib

# build configuration utility
bin/IPCONFIG.o: ipconfig.c
	@echo "Compiling ipconfig.c"
	@cc65 -t apple2 -D__EXEHDR__=0 -o bin/IPCONFIG.asm ipconfig.c
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ bin/IPCONFIG.asm

# build DAN][ assembler interface
bin/dan2if.o: dan2if.asm
	@echo "Assembling dan2if.asm"
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ $<

clean:
	@echo "Clean up..."
	@rm -f bin/*

# for testing: ftp upload of ProDOS image to an DAN][ controller's SD volume
ftp: $(DISK_IMAGE_NAME).po
	@echo "FTP transfer..."
	ftp -u apple2@$(DAN2_FTP_IP):$(DAN2_VOL_IMAGE) $(DISK_IMAGE_NAME).po


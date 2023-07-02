include version.mk

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

FW_VERSION := $(subst ",,$(FW_VERSION))
ZIP_FILE := DANII_Release_v$(FW_VERSION).zip

DISK_FILES := DANIIUTIL.$(FW_VERSION).po DANIIUTIL.$(FW_VERSION).dsk ip65.po ip65.dsk ADTPRO-2.1.D2.PO ADTPRO-2.1.D2.DSK

HEX_FILE := Apple2Arduino/Apple2Arduino.ino.with_bootloader.hex
UTILS    := $(addprefix utilities/,allvols/bin/ALLVOLS.SYSTEM ipconfig/bin/IPCONFIG.SYSTEM fwupdate/bin/FWUPDATE.SYSTEM eeprom/bin/EEPROM.PROG.SYS eeprom/bin/SRAM.PROG.SYS)

release:
	- rm $(ZIP_FILE)
	@zip $(ZIP_FILE) eprom/bin/eprom.bin $(addprefix dsk/,$(DISK_FILES)) $(HEX_FILE) $(UTILS)


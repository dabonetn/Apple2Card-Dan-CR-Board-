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

DISK_FILES := DANII_FW_$(FW_VERSION).po DANII_FW_$(FW_VERSION).dsk ip65.po ip65.dsk DANII_FTP_IPCONFIG.dsk

HEX_FILE := Apple2Arduino/Apple2Arduino.ino.with_bootloader.hex
UTILS := utilities/allvols/bin/ALLVOLS.SYSTEM

release:
	- rm $(ZIP_FILE)
	@zip $(ZIP_FILE) eprom/bin/eprom.bin $(addprefix dsk/,$(DISK_FILES)) $(HEX_FILE) $(UTILS)


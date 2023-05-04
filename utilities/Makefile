TARGETS := all clean

$(TARGETS):
	make -C eeprom $@
	make -C fwupdate $@
	make -C ipconfig $@


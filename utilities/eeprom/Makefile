# firmware makefile
# Thorsten Brehm, 2023

SOURCE    = $(wildcard *.asm)
BINARIES  = $(addprefix bin/,$(SOURCE:.asm=.bin) EEPROM.SYSTEM SRAM.SYSTEM)
FIRMWARE  = ../../eprom/bin/eprom.bin
DISKIMAGE = bin/BlankDriveWithEeprom.po

APPLECOMMANDER = java -jar ../../bootpg/tools/AppleCommander-1.3.5.13-ac.jar

all: bin $(BINARIES) $(DISKIMAGE)

bin:
	mkdir bin 2> /dev/null

bin/%.bin: bin/%.o
	@echo "Linking $@..."
	@ld65 -t none $< -o $@
	@echo ""

bin/%.o: %.asm Makefile
	@echo "Assembling $<..."
	@ca65 $< -o $@ --listing bin/$(<:.asm=.lst) --list-bytes 255

# assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
$(DISKIMAGE): $(BINARIES)
	@echo "Building disk image $@..."
	@rm -f $@
#	@ProDOS-Utilities -c create -d BlankDriveWithFirmware.po -v ROM -s 65535
	@$(APPLECOMMANDER) -pro140 $@ DANII
	@$(foreach binary,$(BINARIES) $(FIRMWARE), cat $(binary) | $(APPLECOMMANDER) -p $@ $(notdir $(binary)) bin 0x2000 &&) true
	@cp $@ ../../dsk/.

list: $(DISKIMAGE)
	@$(APPLECOMMANDER) -l $(DISKIMAGE)

bin/EEPROM.SYSTEM: bin/eeprom_update.bin $(FIRMWARE)
	cat bin/eeprom_update.bin $(FIRMWARE) > $@

bin/SRAM.SYSTEM: bin/sram_update.bin $(FIRMWARE)
	cat bin/sram_update.bin $(FIRMWARE) > $@

clean:
	@echo "Wiping generated files..."
	@rm -f $(BINARIES) $(addprefix bin/,$(SOURCE:.asm=.o) $(SOURCE:.asm=.lst)) $(DISKIMAGE)


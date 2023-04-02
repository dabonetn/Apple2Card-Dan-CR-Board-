# boot program build makefile
# Thorsten Brehm, 2023

BOOTLOADER     = $(wildcard *.asm)
BOOTLOADER_H   = $(addprefix bin/,$(BOOTLOADER:.asm=.h))
BOOTLOADER_BIN = $(addprefix bin/,$(BOOTLOADER:.asm=.bin))

all: test $(BOOTLOADER_H)

bin/%.h: bin/%.bin tools/file2header.py
	@echo "Generating Arduino header file $(notdir $<)..."
	@python3 tools/file2header.py --arduino bootblocks --padding 512 --binary --file $< > $@
	@cp $@ ../Apple2Arduino/$(notdir $@)
	@echo ""

bin/%.bin: bin/%.o
	@echo "Linking $@..."
	@ld65 -t none $< -o $@

bin/%.o: %.asm Makefile | bin
	@echo "Assembling $<..."
	@ca65 $< -o $@ --listing bin/$(<:.asm=.lst) --list-bytes 255

.PRECIOUS: $(BOOTLOADER_BIN)

bin:
	@echo "Making build directory..."
	@mkdir bin

clean:
	@echo "Wiping generated files..."
	@rm bin/*

test:
	@(python3 -V > /dev/null 2> /dev/null) || (echo "ERROR: Python3 installation is required to convert binaries!"; exit 1)


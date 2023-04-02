# firmware makefile
# Thorsten Brehm, 2023

SOURCE   = $(wildcard *.asm)
BINARIES = $(SOURCE:.asm=.bin)

all: $(BINARIES) BlankDriveWithFirmware.po

%.bin: %.o
	@echo "Linking $@..."
	@ld65 -t none $< -o $@
	@echo ""

%.o: %.asm Makefile
	@echo "Assembling $<..."
	@ca65 $< -o $@ --listing $(<:.asm=.lst) --list-bytes 255

# assumes ProDOS-Utilities is in your path: https://github.com/tjboldt/ProDOS-Utilities
BlankDriveWithFirmware.po: $(BINARIES)
	@echo "Building disk image $@..."
	@rm -f $@
	@ProDOS-Utilities -c create -d BlankDriveWithFirmware.po -v ROM -s 65535

clean:
	@echo "Wiping generated files..."
	@rm -f $(BINARIES) $(SOURCE:.asm=.o) $(SOURCE:.asm=.lst) BlankDriveWithFirmware.po



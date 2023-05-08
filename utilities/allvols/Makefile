# firmware makefile
# Thorsten Brehm, 2023

SOURCE    = $(wildcard *.asm)
BINARIES  = $(addprefix bin/,$(SOURCE:.asm=.bin) ALLVOLS.SYSTEM)

all: bin $(BINARIES) $(DISKIMAGE)

bin:
	mkdir bin 2> /dev/null

bin/%.bin: bin/%.o
	@echo "Linking $@..."
	@ld65 -t none $< -o $@
	@echo ""

bin/%.o: %.asm Makefile bin
	@echo "Assembling $<..."
	@ca65 $< -o $@ --listing bin/$(<:.asm=.lst) --list-bytes 255

bin/ALLVOLS.SYSTEM: bin/allvols.bin
	cp $< $@

clean:
	@echo "Wiping generated files..."
	@rm -f $(BINARIES) $(addprefix bin/,$(SOURCE:.asm=.o) $(SOURCE:.asm=.lst)) bin/*.SYSTEM

bin:
	- mkdir bin

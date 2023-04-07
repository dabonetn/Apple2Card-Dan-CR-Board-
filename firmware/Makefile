# firmware makefile
# Thorsten Brehm, 2023

SOURCE   = $(wildcard *.asm)
BINARIES = $(addprefix bin/,$(SOURCE:.asm=.bin))

all: bin $(BINARIES)

bin:
	mkdir bin 2> /dev/null

bin/%.bin: bin/%.o
	@echo "Linking $@..."
	@ld65 -t none $< -o $@
	@echo ""

bin/%.o: %.asm Makefile
	@echo "Assembling $<..."
	@ca65 $< -o $@ --listing bin/$(<:.asm=.lst) --list-bytes 255

clean:
	@echo "Wiping generated files..."
	@rm -f $(BINARIES) $(addprefix bin/,$(SOURCE:.asm=.o) $(SOURCE:.asm=.lst))


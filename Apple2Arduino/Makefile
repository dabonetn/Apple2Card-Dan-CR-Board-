SOURCES := $(wildcard *.ino *.h *.c)

all: Apple2Arduino.ino.with_bootloader.standard.hex
	@echo To burn the firmware under Linux, execute:
	@echo -e "\tminipro -p 'ATMEGA328P@DIP28' -c code -w Apple2Arduino.ino.with_bootloader.standard.hex -f ihex -e"
	@echo -e "\tminipro -p 'ATMEGA328P@DIP28' -c config -w fuses.cfg"

Apple2Arduino.ino.with_bootloader.standard.hex: $(SOURCES)
	arduino-cli compile -b arduino:avr:uno --output-dir . Apple2Arduino.ino

clean:
	rm Apple2Arduino.ino.eep Apple2Arduino.ino.elf Apple2Arduino.ino.hex Apple2Arduino.ino.standard.bin Apple2Arduino.ino.standard.hex


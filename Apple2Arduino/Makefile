SOURCES := $(wildcard *.ino *.h *.c)

HEX_FILE      := Apple2Arduino.ino.with_bootloader.hex

# Override default Arduino Uno settings and provide a custom bootloader
# (must be stored in a "bootloaders" subdirectory, since that's hardcoded in the Arduino environment)
BOOTLOADER    := optiboot_atmega328p_DANII_16000000L.hex
PLATFORM_PATH := $(realpath .)
BUILD_PROPERTIES := --build-property "runtime.platform.path=$(PLATFORM_PATH)" --build-property "bootloader.file=$(BOOTLOADER)"

.PHONY: arduino all

all: build

build: $(HEX_FILE)

# build and add custom bootloader
$(HEX_FILE): $(SOURCES) bin
	@arduino-cli compile -b arduino:avr:uno $(BUILD_PROPERTIES) --output-dir bin Apple2Arduino.ino
	@cp bin/Apple2Arduino.ino.with_bootloader.hex $@

clean:
	@rm -f bin/*.eep bin/*.elf bin/*.hex bin/*.bin

bin:
	@mkdir -p bin

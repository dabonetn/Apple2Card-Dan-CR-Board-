#!/bin/sh 
ca65 eeprom.asm -o eeprom.o --listing eeprom.lst --list-bytes 255 || exit 1
ld65 -t none eeprom.o -o eeprom.bin || exit 1


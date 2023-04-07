#!/bin/sh 
ca65 Firmware.asm -o firmware.o --listing Firmware.lst --list-bytes 255 || exit 1
ld65 -t none firmware.o -o Firmware.bin || exit 1


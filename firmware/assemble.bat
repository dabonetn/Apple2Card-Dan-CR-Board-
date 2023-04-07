..\Ignore\cc65\bin\ca65 Firmware.asm -o bin/firmware.o --listing bin/Firmware.lst --list-bytes 255
..\Ignore\cc65\bin\ld65 -t none bin/firmware.o -o bin/Firmware.bin

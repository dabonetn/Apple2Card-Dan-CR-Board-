..\Ignore\cc65\bin\ca65 flash.asm -o bin/flash.o --listing bin/flash.lst --list-bytes 255 
..\Ignore\cc65\bin\ld65 -t none bin/flash.o -o bin/flash.bin 
..\Ignore\cc65\bin\ca65 allvols.asm -o bin/allvols.o --listing bin/allvols.lst --list-bytes 255 
..\Ignore\cc65\bin\ld65 -t none bin/allvols.o -o bin/allvols.bin 
copy /b bin/flash.bin+../Firmware/bin/Firmware.bin bin/flash.system

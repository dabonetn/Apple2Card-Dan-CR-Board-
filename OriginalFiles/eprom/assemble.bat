..\Ignore\cc65\bin\ca65 eprom.asm -o bin/eprom.o --listing bin/eprom.lst --list-bytes 255
..\Ignore\cc65\bin\ld65 -t none bin/eprom.o -o bin/eprom.bin

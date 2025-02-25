set BOOTLOADER= bootpg_stock_v2 bootpg_v3 bootpg_cursor_v4

mkdir bin 2> NUL

for %%f in (%BOOTLOADER%) do (
..\Ignore\cc65\bin\ca65 %f.asm -o bin/%f.o --listing bin/%f.lst --list-bytes 255
..\Ignore\cc65\bin\ld65 -t none bin/%f.o -o bin/%f.bin
echo const uint8_t bootblocks[] PROGMEM = { > bin/%f.h
c:\msys64\usr\bin\xxd.exe -i < %f.bin >> bin/%f.h
echo }; >> bin/%f.h
copy bin/%f.h ../Apple2Arduino/.
)


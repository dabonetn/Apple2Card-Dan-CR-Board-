# Makefile - build FTP/IP configuration utility/disk.
#
#  Copyright (c) 2023 Thorsten C. Brehm
#
#  This software is provided 'as-is', without any express or implied
#  warranty. In no event will the authors be held liable for any damages
#  arising from the use of this software.
#
#  Permission is granted to anyone to use this software for any purpose,
#  including commercial applications, and to alter it and redistribute it
#  freely, subject to the following restrictions:
#
#  1. The origin of this software must not be misrepresented; you must not
#     claim that you wrote the original software. If you use this software
#     in a product, an acknowledgment in the product documentation would be
#     appreciated but is not required.
#  2. Altered source versions must be plainly marked as such, and must not be
#     misrepresented as being the original software.
#  3. This notice may not be removed or altered from any source distribution.

# AppleCommander
AC := java -jar ../../bootpg/tools/AppleCommander-1.3.5.13-ac.jar

all: bin bin/IPCONFIG.SYSTEM

# build ProDOS executable
bin/IPCONFIG.SYSTEM: bin/IPCONFIG.o bin/dan2if.o
	@echo "Linking $@"
	@ld65 -C apple2-system.cfg  -D __EXEHDR__=0 -m bin/IPCONFIG.list -o $@ bin/IPCONFIG.o bin/dan2if.o apple2.lib

# build configuration utility
bin/IPCONFIG.o: ipconfig.c Makefile
	@echo "Compiling ipconfig.c"
	@cc65 -t apple2 -D__EXEHDR__=0 -o bin/IPCONFIG.asm ipconfig.c
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ bin/IPCONFIG.asm

# build DAN][ assembler interface
bin/dan2if.o: dan2if.asm Makefile
	@echo "Assembling dan2if.asm"
	@ca65 -t apple2 -D__EXEHDR__=0 -o $@ $<

clean:
	@echo "Clean up..."
	@rm -f bin/*

bin:
	- mkdir bin

# hex2bin.py - super simple intel hex to binary converter.
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

import sys

def readfile(name):
	with open(name, "r") as f:
		return f.readlines()

def checksum(data):
	return ((sum(data) ^ 0xff)+1)&0xff

def hex2bin(InputFileName, OutputFileName, ImageSize, FillByte=0xff):
	IntelHexText = readfile(InputFileName)

	Image = bytearray(65536*bytes([FillByte]))
	LineNumber = 0
	SegmentAddress = 0
	Ok = False
	MaxAddr = 0
	for LineNumber in range(len(IntelHexText)):
		Line = IntelHexText[LineNumber].rstrip()
		if Line.startswith(":"):
			Bytes = bytearray([])
			for b in range((len(Line))//2):
				Bytes.append(int(Line[1+b*2:3+b*2],16))
			ByteCount = Bytes[0]
			Addr      = (Bytes[1]<<8) + Bytes[2] + SegmentAddress
			RecType   = Bytes[3]
			Data      = Bytes[4:-1]
			if 0 != checksum(Bytes):
				Crc = Bytes[-1]
				raise RuntimeError("Invalid checksum "+hex(Crc)+" in line "+str(LineNumber+1))
			if RecType == 0:                                # data record
				Image[Addr:Addr+ByteCount] = Data
				if (Addr + ByteCount) > MaxAddr:
					MaxAddr = Addr + ByteCount
			elif RecType == 1:				# end of file
				Ok = True
				break
			elif RecType == 4:				# extended linear address
				if ByteCount != 2:
					raise RuntimeError("Invalid byte count for SREC type 4: "+hex(ByteCount)+" in line "+str(LineNumber+1))
				SegmentAddress = (Data[0] << 24) | (Data[1] << 16)
			elif RecType == 5:				# execution start address: ignored for conversion
				pass
			else:
				raise RuntimeError("Unsupported SREC type: "+hex(RecType)+" in line "+str(LineNumber+1))
	if not Ok:
		raise RuntimeError("Missing end-of-file marker. Hex file is incomplete.")
        # write image file - limited to requested maximum size
	with open(OutputFileName, "wb") as f:
		f.write(Image[0:ImageSize])

def run(args):
	Ok        = False
	FillByte  = 0xFF
	ImageSize = 65536
	args      = args[1:]
	while len(args)>0:
		if args[0] == "--fillbyte":
			Fillbyte = int(args[1])
			args = args[2:]
		elif args[0] == "--size":
			ImageSize = int(args[1])
			args = args[2:]
		else:
			if args[0].startswith("--"):
				sys.stderr.write("Unknown parameter: "+args[0]+"\n")
			else:
				Ok = True
			break

	if (Ok)and(len(args)==2):
		InputFile  = args[0]
		OutputFile = args[1]
		hex2bin(InputFile, OutputFile, ImageSize, FillByte)
	else:
		sys.stderr.write("\n"
		                 "Usage: python3 file2header.py [--size <value>] inputfile outputfile\n\n"
		                 "  --size <value>     size of the resulting binary image\n\n"
		                 "  --fillbyte <value>     fillbyte for unused memory areas (usually 0 or 255)\n\n")

run(sys.argv)

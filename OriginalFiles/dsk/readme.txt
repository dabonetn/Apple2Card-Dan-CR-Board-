Explanation of disk images and volumes:

====================
APPLE II Disk Images
====================

DANIITOOL.xxx.dsk:
	Disk image with DAN][ utilities for Apple II: firmware updater, "all volumes" utility etc.
	Disk image is in normal Apple II disk format.
	Can be written to a real disk or used with "FloppyEmu".

DANIITOOL.xxx.po:
	The same as the corresponding .dsk file, however, in "ProDOS disk format" (.po).
	Can be used as a ProDOS volume (also on the SD-cards of the DAN][ controller itself,
	or used with "FloppyEmu").

ADTPRO-xxx.DSK:
	ADTPro disk built with DAN][ Ethernet support.
	Can be used like any other ADTPro disk, but also offers the option of using the
	ADTPRO Ethernet connection, using the DAN][ Controllers optional Ethernet
	module (Wiznet 5500).
	Can be written to a real disk or used with "FloppyEmu".

ADTPRO-xxx.po:
	The same as the corresponding .dsk file, however, in "ProDOS disk format" (.po).
	Can be used as a ProDOS volume (also on the SD-cards of the DAN][ controller itself,
	or used with "FloppyEmu").

ip65.dsk:
        Example floppy disk image (.dsk format) containing the IP65 network stack for the DAN][ card
        and some example programs. These demonstrate the use of the DAN][ as an Ethernet interface
        for the Apple II, where the 6502 CPU takes control of the network interface.

ip65.po:
        Same as the earlier floppy disk image, however, as a volume in ProDOS format (.po).
        This file can be stored directly as volume on the SD card of the DAN][ card.


===============================
APPLE /// Disk Images & Volumes
===============================

FLOPPY_APPLE3_DAN2_FWUPDATE.xxx.dsk:
	Firmware update floppy image for Apple ///. This contains a native Apple /// SOS
	application to update the firmware of the DAN][ card. This volumes needs to be written
	to a real floppy (e.g. using ADTPro), or can be loaded from a FloppyEmu.

VOLxx_APPLE3_DAN2_FWUPDATE.xxx.po:
	Firmware update volume for __Apple ///__. Contains the same firmware update as the floppy disk,
	however, this volume is to be stored as a volume on the SD card of the DAN][ card itself. It can
	be booted directly from the card (but you need the usual DAN][ boot disk or Apple III custom ROM).


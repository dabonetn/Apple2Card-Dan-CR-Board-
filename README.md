# DAN][Controller: Apple II Storage Interface, Arduino Interface & Network Interface

# Introduction
The DAN][Controller is a simple and easy to build card that provides two SD cards as mass storage devices to ProDOS.

Optionally it can be extended with a network interface using a Wiznet W5500 adpater.
The network interface provides an optional FTP server to remotely manage the Apple II volumes on the two SD cards. The network interface can also be used by the Apple II itself (using the IP65 network stack).

The card is based on the ATMEGA328P which is programmed with the Arduino development environment. It uses an using a 82C55 peripheral interface to connect to the Apple II bus.
The design uses only five commonly available integrated circuits, the 74HCT08 AND gate, 74HCT32 OR gate, 82C55A peripheral interface, an eprom/eeprom memory chip, and a ATMEGA328P microcontroller, so should be reasonably future-proofed as much as any design for a 40 year old computer can be.

![Apple2Card](pics/DAN2Controller.jpg)

# PCBs
The gerbers for the PCB are in the [Apple2Card/Gerber](/Apple2Card/Gerber) directory. You can directly send the [Apple2Card-Gerber.zip](/Apple2Card/Gerber/Apple2Card-Gerber.zip) to a PCB service like JLCPCB or PCBway, for example.

![Apple2Card](Apple2Card/Apple2Card.png)

## Connectors
* The **J1** connector is the ICSP connector for programming the ATMEGA32P.
* The **J2** and **J3** connector break out the bus pins of the Apple II.
* The **J4** connect are the extra pins of the 82C55 broken out onto a connector.
* The **J5** connector is for debugging.
* The **J6** connector is for a Wiznet 5500 SPI ethernet controller (similar to Uthernet).

# Programming the Devices

## EPROM/EEPROM
For the memory device of the card an EPROM or EEPROM of 4K/8K/16K/32K can be used: a 27C32/27C64/27C128/27C256 EPROM or a 28C32/28C64/28C128/28C256 EEPROM.
Only the first 512 bytes of that memory are used. Most of the code (including the boot/configuration program for the card) is stored in the Arduino flash memory - not in the EPROM - so the contents of this memory device are not expected to change often (while the ATMEGA chip's internfal flash will be subject to more frequent updates).

The (E)EPROM needs to be programmed with this [eprom.bin](/eprom/bin/eprom.bin) file. It is a 512 byte file that can be burnt to the memory chip using a programmer (such as a TL866 plus II).
Again, only the first 512 bytes are used.

If an EEPROM is used, there is also a program called [EEPROM.SYSTEM](utilities/eeprom/bin/EEPROM.SYSTEM) which can program the EEPROM on the board.
Jumpers JP2, JP3, JP4, JP6, JP7, JP8, JP9, and JP10 need to be closed when programming the EEPROM with the EEPROM.SYSTEM program.

**However, for normal use, jumpers JP3-JP10 must be open - while only JP2 must be closed** (you can hardwire/solder JP2 to be closed).

## ATMEGA328P
The code for the ATMEGA328P is the Apple2Arduino sketch in the [Apple2Arduino](Apple2Arduino/) directory.
It can be uploaded using a programmer, however, preferably this [custom bootloader](Apple2Arduino/ArduinoBootloader_optiboot_atmega328p_DANII_16000000L.hex) should be installed to the ATMEGA.
Once the custom bootloader is installed, the Apple II is able to update the firmware of the ATMEGA (no more cables or ICSP programmers required).
The fw update utility can even be used to program the initial firmware (or to recover a "brain dead" ATMEGA - when the custom bootloader was installed).
See the latest ZIP in [releases](https://github.com/ThorstenBr/Apple2Card/releases) with a disk containing the Arduino firmware update utility for the Apple II.

The recommended fuse settings for the ATMEGA328P are identical to the default settings of an Arduino Uno board:

* **lfuse: 0xFF**
* **hfuse: 0xDE**
* **efuse: 0xFD**

(The hfuse setting activates the use of the bootloader).

You can program the ATMEGA328P using a programmer (such as a TL866 plus II).
You can also use an ICSP programmer (such as an Ardunio Uno board, programmed with the "Arduino as ISP" sketch), connect the ICSP cable to the **J1** connector of the DAN][Card and directly program the the ATMEGA328P on the board.

**If you use the ICSP connector of the DAN][Card then no SD cards should be present in the SD slots when the ATMEGA328P is flashed.**

A command-line for programming the fuses and bootloader with "avrdude" is:

`avrdude -c avrisp -p m328p -P /dev/ttyUSB0 -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0xFD:m -Uflash:w:ArduinoBootloader_optiboot_atmega328p_DANII_16000000L.hex`

You may need to adapt "avrisp" and the "/dev/ttyUSB0" port to match your programmer device. The "avrisp" matches the ArduinoISP (e.g. an Arduino Uno board programmed to be an ISP).

Alternatively, the Arduino sketch can be uploaded directly with the Arduino environment.

# SD Cards
Either micro SD or micro SDHC cards may be used - with up to 32 GB capacity.

## FAT16/FAT32 Mode
You can use SD cards with either FAT16 or FAT32 file system as the first partition.
In FAT mode, the individual Apple II volumes on the SD card must be stored in the root directory of the card and must be named **BLKDEV01.PO** - **BLKDEV09.PO** or **BLKDEV0A.PO** - **BLKDEV0F.PO** (up to 15 volumes). These volumes need to contain normal Apple II ProDOS volumes (between 140K to 33MB).

An empty ProDOS volume file of 33MB is provided within the ZIP file [SingleBlankVol.zip](/volumes/SingleBlankVol.zip).

## Raw Block Mode
Alternatively, raw block mode may be used (instead of FAT formatted SD cards). Only the first 512 MB will be used for raw blocks.

To prepare SD cards for raw block mode, use the [BlankVols.zip](/volumes/BlankVols.zip) file. Unzip this file. The resulting "Blankvols.PO" file has a size of 512 MB. This needs to be written to a SD card using an utility such as Win32DiskImager or "dd" under linux. This file contains 16 concatenated and properly formatted (empty) ProDOS volumes. Place this in SLOT1 of the card.

## Wide Block Mode ###
TBD: Ordinarily, only a maximum of 64 MB is addressable, 32 MB for ProDOS drive 1, and a second 32 MB for ProDOS drive 2.  The program ALLVOLS.SYSTEM allows this limit to be circumvented in ProDOS 8.  For a SD card placed in slot 1, write the image in "BlankVols" or "BlankVolsSlot1"to it, and for a SD card in slot 2, write the image file "BlankVolsSlot2" to it.  When ALLVOLS.SYSTEM is executed, extra volumes may be added from slot 1 or slot 2 depending on if a SD card with block images is present in slot 1 or slot 2.  It is recommended that slot 1 be used for block images and slot 2 be used for FAT FS images.  This way, cards can be swapped in and out of slot 2 with different files transferred from another computer (perhaps using CiderPress) while the boot filesystem in slot 1 stays the same.

## Preparing ProDOS volumes
ProDOS disk images can be read/written by software such as CiderPress ([a2ciderpress.com](https://a2ciderpress.com/)) so that you can use this to transfer files to and from the Apple II.
Files can be copied onto the ProDOS disk image partition which can then be read/written by CiderPress and transferred to other media.

To make a volume bootable, copy the "PRODOS.SYSTEM" and other system files to be started on booting, for example "BASIC.SYSTEM".

# Installation
The card can be installed in any Apple II slot, but slot 7 is a good choice: the Apple II starts at the highest slot number (slot 7) when searching for a bootable device.
Usually a floppy controller is installed in slot 6. So the DAN][Card should be installed in slot 7 to make it the first boot device.

# Booting the Apple II
When the card is the primary boot device then the message "DAN II: PRESS RETURN" appears on the bottom of the screen when the Apple II is booting. 

* If the **RETURN** key is pressed, then the boot menu is loaded to configure the card (see below).
* If the **ESCAPE** key is pressed, then the DAN][ Controller is skipped and the Apple II will search for the next boot device (e.g. your floppy drive).
* If any of the keys **1** to **9** are pressed, then the respective volume from SD card 1 is booted (quick access).
* If **no key** is pressed, then normal booting continues after about a second. This will boot the volume which was *most recently* selected through the boot menu.
* If **SPACE** is pressed, then normal booting continues immediately (most recent boot menu selection).

## Boot menu
If the RETURN key is pressed during boot up, the boot menu is loaded.
The boot menu allows the selection of the volumes.

![Boot menu](pics/bootmenu.jpg)

Use the **ARROW KEYS** (or **SPACE**/**TAB**/**BACKSPACE**) to select the active volume for each SD card. Press **ESCAPE** to abort and **RETURN** to confirm.

You can also select volumes through the number keys **1** to **9**.

After selecting the volumes of the two slots, the system continues booting.

# Ethernet/Network Interface
The card can be extended with an Ethernet interface. A cheap Wiznet 5500 device can be connected to **J6** using a ribbon cable as indicated:

![Wiznet Network Adapter](pics/wiznet.jpg)

It's recommended to leave out the two resistors R27 and R28 on the controller PCB when you connect the WIZnet. These resistors connect signals to the J6 header which are not meant for the WIZnet device.

![Resistors](pics/wiznet_resistors.jpg)

LED D11 (just above the J6 header) indicates network activity of the WIZnet adapter.

The [CAD](/CAD) folder contains a design for 3D printed bracket, which can be used to mount the WIZnet Ethernet adapter into the back of the Apple II.

## FTP Access ##
When the Ethernet adapter is installed you can use FTP to remotely access the SD cards. The FTP access is very limited and only allows up- and downloading volumes to the volume files. The volumes are shown in two separate directories (SD1 and SD2) and list the volume files BLKDEV01.PO-BLKDEV0F.PO. Other files and other directories are not accessible via FTP (any unrelated files and folders will stay on the SD cards, but neither be visible nor writable via FTP).

The Apple II access is suspended as soon as any FTP session is active. Disconnect your FTP client to resume Apple II access to the volumes.

Notice that any RESET of the Apple II also resets the DAN][Controller and the network device. So avoid pressing Ctrl-RESET on the Apple II while up- or downloading volume images via FTP.

## IP Configuration ##
The IP address for FTP is currently configured using a separate tool. See the [dsk](/dsk) folder for disk images with the IP configuration tool. The ".PO" image can also be stored as a volume on the DAN][ Controller.

*This tool (disk) will eventually be replaced by an option integrated into the normal boot menu (come back to check for updates soon :) ).*

### Advanced FTP clients ###
The FTP server is limited to a single connection. If you use advanced FTP clients, like FileZilla, then you need to configure the FTP connection: see the "connection properties" and enable "Limit number of simulataneous connections" and set the limit to "1":

![FileZilla Configuration](pics/FileZillaConfig.png)

### Advanced FTP features ###
Notice that ProDOS volume names and volume sizes are displayed via FTP. The owner/group information is (ab)used to report the ProDOS volume name - while the normal FTP file names are the normal DOS file names.

![FTP Volume Display](pics/FTPVolumeDisplay.png)

## Apple II Ethernet Access ##
Alternatively to the FTP support, it is also possible for the Apple II to directly access the WIZnet Ethernet port. There is an extension for the IP65 network stack which adds support for the DAN][Controller interface to the WIZnet adapter.
See the [dsk](/dsk) folder for an example disk with IP65 examples (telnet client, ntp time synchronisation etc).

Notice that the FTP server on the DAN][ Controller is shutdown whenever the Apple II directly accesses the Ethernet port (using IP65).

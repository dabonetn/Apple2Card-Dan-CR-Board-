/*
   Copyright (c) 2022 Daniel Marks
   Copyright (c) 2023 Thorsten Brehm

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

#include "config.h"
#include "dan2volumes.h"
#include "diskio_sdc.h"
#ifdef USE_FAT_DISK
#include "ff.h"
#endif

request_t request;     // the slot/file/volume which is requested for access
FATFS     current_fs;    // the FATFS which is currently mounted
FIL       current_file;  // the FAT file which is currently mounted
uint8_t   current_filenum = 255; // the file number which is currently accessed (FAT or RAW)
int8_t    slot_type[2]  = {SLOT_TYPE_UNKNOWN, SLOT_TYPE_UNKNOWN}; // the detected disk format (RAW/FAT/nothing)

static char blockdev_filename[] = "X:BLKDEVXX.PO"; // the currently mounted drive (and file)

#define FILE_VALID(file) ((file)->obj.fs != NULL) // check if the FS object is valid

// map number 0-$F to single hex character
uint8_t hex_digit(uint8_t ch)
{
  return (ch < 10) ? (ch + '0') : (ch + ('A'- 10));
}

#ifdef USE_FAT_DISK
// mount a FAT disk of given SD card
bool vol_mount(uint8_t sdslot)
{
  sdslot += '0'; // map to alphanum character
  if (blockdev_filename[0] != sdslot) // already mounted?
  {
    if (blockdev_filename[0] != 'X') // anything else mounted?
    {
      if (FILE_VALID(&current_file)) // any open file?
      {
        f_close(&current_file);
        current_filenum = 255;
      }
      f_unmount(blockdev_filename); // unmount the volume (ignores the filename)
    }
    blockdev_filename[0] = sdslot;
    if (f_mount(&current_fs, blockdev_filename, 1) != FR_OK) // this only mounts the volume, ignores the filename
    {
      blockdev_filename[0] = 'X'; // invalidate current drive
      return false;
    }
  }
  return true;
}
#endif

// determine the SD card format (RAW/FAT/nothing)
void vol_check_sdslot_type(uint8_t sdslot)
{
  // file system type known yet?
  if (slot_type[sdslot] == SLOT_TYPE_UNKNOWN)
  {
#ifdef USE_FAT_DISK
    if (vol_mount(sdslot)) // immediate mount
    {
      slot_type[sdslot] = SLOT_TYPE_FAT;  // FAT FS detected
    }
    else
#endif
    {
      slot_type[sdslot] = SLOT_TYPE_NODISK;

#ifdef USE_RAW_DISK
      // It's not a FAT disk. But is it raw/ProDOS disk?
      current_fs.winsect = -1; // invalidate sector window
      if (disk_read(sdslot, current_fs.win, 2, 1) != 0) // read sector 2 with ProDOS header of volume 1
      {
        // no disk or invalid format
        return;
      }

      if ((current_fs.win[4]<=0xf0)&& // check key block (with valid volume name)
          (0x0D27 != *((uint16_t*)&current_fs.win[0x23]))) // check entry length/entries per block=$27/$0D
      {
        return;
      }

      // seems legit: raw block disk with ProDOS header in volume 1
      slot_type[sdslot] = SLOT_TYPE_RAW;
#endif
    }
  }
}

// prepare the requested slot/volume/file for access
bool vol_open_drive_file(void)
{
  // file access disabled
  if (request.sdslot > 1)
    return false;

#ifdef USE_RAW_DISK
  // RAW format? No open required
  if (slot_type[request.sdslot] == SLOT_TYPE_RAW)
  {
    return true;
  }
#endif

#ifdef USE_FAT_DISK
  // no disk or unable to mount?
  if ((slot_type[request.sdslot] <= SLOT_TYPE_UNKNOWN)||
      (!vol_mount(request.sdslot)))
  {
    return false;
  }

  // file already open?
  if (current_filenum == request.filenum)
    return true;

  // open file
  blockdev_filename[8] = hex_digit(request.filenum >> 4);
  blockdev_filename[9] = hex_digit(request.filenum & 0x0F);
  if (f_open(&current_file, blockdev_filename, FA_READ | FA_WRITE) == FR_OK)
  {
    current_filenum = request.filenum;
    return true;
  }
#endif

  return false;
}

// read a block from disk or from the boot program area, returns 0=OK
uint8_t vol_read_block(uint8_t* buf)
{
  if (!vol_open_drive_file())
    return PRODOS_NODEV_ERR;

#ifdef USE_RAW_DISK
  if (slot_type[request.sdslot] == SLOT_TYPE_RAW)
  {
      uint32_t sector = request.filenum;
      sector <<= 16;
      sector |= request.blk;
      if (disk_read(request.sdslot, buf, sector, 1) != RES_OK)
      {
        return PRODOS_IO_ERR;
      }
  }
  else
#endif
#ifdef USE_FAT_DISK
  {
    UINT br;

    // convert blocks to bytes
    uint32_t FileOffset = request.blk;
    FileOffset <<= 9;
    // only seek when necessary
    if ((f_tell(&current_file) != FileOffset)&&(f_lseek(&current_file, FileOffset) != FR_OK))
    {
      return PRODOS_IO_ERR;
    }
    if ((f_read(&current_file, buf, 512, &br) != FR_OK) ||
        (br != 512))
    {
      return PRODOS_IO_ERR;
    }
  }
#else
  {
    return PRODOS_NODEV_ERR;
  }
#endif

  return PRODOS_OK;
}

// write a block to disk: returns 0=OK or PRODOS error code
uint8_t vol_write_block(uint8_t* buf)
{
  UINT br;
  if (!vol_open_drive_file())
    return PRODOS_NODEV_ERR;

#ifdef USE_RAW_DISK
  if (slot_type[request.sdslot] == SLOT_TYPE_RAW)
  {
    uint32_t sector = request.filenum;
    sector <<= 16;
    sector |= request.blk;
    if (disk_write(request.sdslot, buf, sector, 1) != RES_OK)
      return PRODOS_IO_ERR;
  }
  else
#endif
#ifdef USE_FAT_DISK
  {
    // convert blocks to bytes
    uint32_t FileOffset = request.blk;
    FileOffset <<= 9;

    // do not allow to write beyond the current file size
    if (FileOffset+512 > f_size(&current_file))
      return PRODOS_IO_ERR;

    // only seek when necessary
    if ((f_tell(&current_file) != FileOffset)&&(f_lseek(&current_file, FileOffset) != FR_OK))
      return PRODOS_IO_ERR;

    if ((f_write(&current_file, buf, 512, &br) != FR_OK) ||
        (br != 512))
      return PRODOS_IO_ERR;
  }
#else
  {
    return PRODOS_NODEV_ERR;
  }
#endif

  return PRODOS_OK;
}

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

#pragma once

#include <Arduino.h>
#include "ff.h"

#define PRODOS_OK             0x0
#define PRODOS_IO_ERR         0x27
#define PRODOS_NODEV_ERR      0x28
#define PRODOS_WRITEPROT_ERR  0x2B

#define SLOT_STATE_NODEV    0
#define SLOT_STATE_BLOCKDEV 1
#define SLOT_STATE_FILEDEV  2

#define SLOT_TYPE_NODISK   -1
#define SLOT_TYPE_UNKNOWN   0
#define SLOT_TYPE_FAT       1
#define SLOT_TYPE_RAW       2

#define SDSLOT1             0
#define SDSLOT2             1

typedef struct {
  uint8_t  sdslot;   // access: which SD slot
  uint8_t  filenum;  // access: which file/block device number
  uint16_t blk;      // access: which 512byte block (LBA)
} request_t;

extern request_t request;
extern FIL       current_file;
extern int8_t    slot_type[2];

uint8_t hex_digit          (uint8_t ch);
uint8_t vol_read_block     (uint8_t* buf);
uint8_t vol_write_block    (uint8_t* buf);
void    vol_check_sdslot_type(uint8_t sdslot);
bool    vol_open_drive_file(void);


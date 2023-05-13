/* Apple2Arduino firmware */
/* by Daniel L. Marks */

/*
   Copyright (c) 2022 Daniel Marks

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

#include "ff.h"
#include "config.h"

#define SLOT_STATE_NODEV    0
#define SLOT_STATE_BLOCKDEV 1
#define SLOT_STATE_WIDEDEV  2
#define SLOT_STATE_FILEDEV  3

#define SLOT_TYPE_UNKNOWN   0
#define SLOT_TYPE_FAT       1
#define SLOT_TYPE_RAW       2

#define RD_DISK             0 // always read disk
#define RD_FAILSAFE         1 // read disk or boot block, if volume/disk is missing
#define RD_BOOT_BLOCK       2 // always read boot block

extern "C" {
  void unmount_drive(void);
  void initialize_drive(void);
  uint8_t hex_digit(uint8_t ch);
  uint8_t check_unit_present(void);
  uint8_t read_block(uint8_t rdtype, uint8_t* buf);
  uint8_t write_block(uint8_t* buf);
#ifdef USE_MEM_CHECK
  void check_memory(int id);
#endif
}

#ifdef USE_MEM_CHECK
  #define CHECK_MEM(id) check_memory(id)
#else
  #define CHECK_MEM(id) {}
#endif

extern uint8_t  unit;
extern uint32_t blockloc;
extern FIL      slotfile;
extern uint8_t  slot_fileno[2];
extern uint8_t  slot_state[2];
extern uint8_t  slot_type[2];

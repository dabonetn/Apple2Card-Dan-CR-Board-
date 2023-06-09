/* ipconfig.c - simple configuration utility for DANII FTP/IP address.

  Copyright (c) 2023 Thorsten C. Brehm

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

#include <stdio.h>
#include <apple2.h>
#include <conio.h>

typedef unsigned char uint8_t;
typedef unsigned int  uint16_t;

// ID to check presence of a DAN][ controller (actually a ProDOS interface header)
uint8_t danID[8] = {0xE0, 0x20, 0xA0, 0x00, 0xE0, 0x03, 0xA2, 0x3C};
uint8_t* INVFLG = (uint8_t*) 0x32;

void norm()    {*INVFLG = 0xff;}
void inverse() {*INVFLG = 0x3f;}

void memcpy(uint8_t* dest, const uint8_t* src, int bytes)
{
  int i;
  for (i=0;i<bytes;i++)
  {
    dest[i] = src[i];
  }
}

// check if a DAN][ controller is installed in given slot
int checkDanSlot(unsigned int slot)
{
  int i;
  uint8_t* p = (uint8_t*) 0xC000;
  p += (slot<<8);

  for (i=0;i<8;i++)
  {
    if (p[i] != danID[i])
      return 0;
  }
  return 1;
}

void main(void)
{
  char c=0;
  char slot=0;
  uint8_t* p = (uint8_t*) 0x800;

  // wipe screen
  clrscr();

  printf("\n");
  inverse();
  printf("            DANII CONTROLLER           \n");
  printf("            FIRMWARE UPDATER           \n");
  norm();

  do
  {
    printf("\nCONTROLLER SLOT: #");
    slot = getc(stdin);
    printf("\n");
    if ((slot>='1')&&(slot<='7'))
    {
      slot -= '0';
      if (checkDanSlot(slot) == 0)
      {
        printf("SORRY, NO DANII CONTROLLER IN #%hu.\n", slot);
        slot = 0;
      }
    }
    else
    {
      printf("INVALID SLOT NUMBER! USE 1-7.\n\x07");
      slot = 0;
    }
  } while (slot == 0);

  p[0x20] = slot;

  printf("\n");
  printf("PRESS\n      ");
  inverse();
  printf("<CTRL-RESET>");
  norm();
  printf(" TO START UPDATE\n");
  printf("      OR ANY OTHER KEY TO ABORT.\n");

  asm("jsr setFwUpdateHook");   // install warm start vector for FW update
  getc(stdin);
  asm("jsr clearWarmStartVec"); // clear warm start vector for FW update

  printf("\n\nFIRMWARE UPDATE ABORTED!\n");
  getc(stdin);
}


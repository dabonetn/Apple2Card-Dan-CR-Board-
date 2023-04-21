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

typedef unsigned char uint8_t;
typedef unsigned int  uint16_t;

uint8_t ip[4];
// default WIZnet MAC address
uint8_t mac[6]   = {0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED};
// ID to check presence of a DAN][ controller (actually a ProDOS interface header)
uint8_t danID[8] = {0xE0, 0x20, 0xA0, 0x00, 0xE0, 0x03, 0xA2, 0x3C};

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

// set or get DAN][ controller's FTP IP configuration
int doDanConfig(uint8_t slot, uint8_t setConfig)
{
   volatile uint8_t* p = (volatile uint8_t*) 0x800;
   int c=0;
   
   for (c=0;c<512;c++)
   {
      p[c] = 0x0;
   }

   // copy MAC+IP address to the configuration structure
   memcpy((uint8_t*) p, mac, 6);
   memcpy((uint8_t*) &p[6], ip, 4);
   
   // simplified assembler interface: just pass the slot+command somewhere in memory
   p[0x20] = slot;
   if (setConfig)
		p[0x21] = 0x20; // command 0x20: set IP config
   else
		p[0x21] = 0x21; // command 0x21: get IP config
   
   // call assembler function to get or set the configuration
   asm("jsr dan2if_do");

   // copy result after a "get config" operation
   if (setConfig==0)
   {
      // we only ever change the last byte of the MAC address
      mac[5] = p[5];
      memcpy(ip, (uint8_t*) &p[6], 4);
   }

   // return the error code (0=ok)
   return p[0x20];
}

void main(void)
{
   char c=0;
   char slot=0;
   int e,v;
   char str[32];

   // wipe screen
   for (e=0;e<24*2;e++)
   	printf("\n");

   printf("\n");
   printf("          DANII CONTROLLER\n");
   printf("        FTP/IP CONFIGURATION\n\n");

   do
   {
        printf("\nController slot: #");
   	slot = getc(stdin);
   	printf("\n");
   	if ((slot>='1')&&(slot<='7'))
   	{
	   slot -= '0';
	   if (checkDanSlot(slot) == 0)
	   {
	     printf("Sorry, no DANII controller in #%hu.\n", slot);
	     slot = 0;
	   }
	}
	else
	{
	  printf("Invalid slot number! Use 1-7.\n\x07");
	  slot = 0;
	}
   } while (slot == 0);

   if (doDanConfig(slot, 0) != 0)
   {
   	printf("\nERROR: controller missing FTP support.\nDid you update the Arduino firmware?\n\x07");
   }
   else
   {
	printf("\nCurrent configuration:\n");
	printf(" SLOT: %hu\n", slot);
        printf(" IP  : %hu.%hu.%hu.%hu\n", ip[0], ip[1], ip[2], ip[3]);
        printf(" MAC : %02hX:%02hX:%02hX:%02hX:%02hX:%02hX\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);


	printf("\nNew configuration:\n");
	do
	{
		printf(" IP  : ");
		gets(str);
		ip[0]=ip[1]=ip[2]=ip[3]=0;
		e = sscanf(str, "%hu.%hu.%hu.%hu", &ip[0], &ip[1], &ip[2], &ip[3]);
		if ((e!=4)||(ip[0]==0)||(ip[1]==0))
		{
		      printf("\n Not a valid IP address!\n\x07");
		      e=0;
		}
	} while (e!=4);

	printf("  Random byte for unique MAC (00-FF):\n");
	do
	{
	        printf(" MAC : %02hX:%02hX:%02hX:%02hX:%02hX:", mac[0], mac[1], mac[2], mac[3], mac[4]);
		gets(str);
		e = sscanf(str, "%hx", &v);
		if ((e!=1)||(v<0)||(v>255))
		{
			printf("\n Pick a random number 00-ff!\n\x07");
			e=0;
		}
	} while (e!=1);
	mac[5] = v;

	printf("\nConfiguring DANII-WIZnet:\n");
	printf(" SLOT: %hu\n", slot);
	printf(" IP  : %hu.%hu.%hu.%hu\n", ip[0], ip[1], ip[2], ip[3]);
	printf(" MAC : %02hX:%02hX:%02hX:%02hX:%02hX:%02hX\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);

	printf("\n          <RETURN> to confirm.");
	gets(str);
	printf("\n");

	// set the new configuration	
	if (doDanConfig(slot, 1) == 0)
	{
		printf("\n           Configuration OK!");
		printf("\n   (CTRL-RESET to activate new IP!)\x07\n");
	}
	else
	{
		printf("\nERROR: controller missing FTP support.\n"
		       "Did you update the Arduino firmware?\x07");
	}
   }
   gets(str);
}


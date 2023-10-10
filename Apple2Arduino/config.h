/* DAN][ configuration */

/**********************************************************************************
 MAIN FEATURES
 *********************************************************************************/
#define USE_ETHERNET     // enable 6502 Ethernet support (IP forwarding / IP65)
#define USE_FTP          // enable FTP support (integrated FTP server, independent of IP65)
#define USE_FAT_DISK     // enable FAT support
#define USE_RAW_DISK     // enable raw disk support

/**********************************************************************************
 DEBUGGING
 *********************************************************************************/
#undef USE_MEM_CHECK     // enable this for memory overflow checks
#undef DEBUG_SERIAL      // enable this for serial debug output
//#define DEBUG_BYTES  8   // only for debugging: enable capturing some debug bytes

/**********************************************************************************
 BOOT MENU PROGRAM
 *********************************************************************************/
/* Select boot program:
  1=no boot program
  2=original/stock v2 bootprogram by DL Marks
  3=bootpg with improved GUI (512byte)
  4=bootpg with cursor key controls (1024byte)
  5=bootpg with IP configuration option (1536byte)
  6=bootpg with flexible volume/SD card mapping
  7=bootpg with support for 128 volumes per SD card
*/
#define BOOTPG 7

/**********************************************************************************
 DEFAULT FTP CONFIGURATION
 *********************************************************************************/

// default IPv4 address (4 bytes, comma separated)
#define FTP_IP_ADDRESS 0,0,0,0 // disabled by default (needs to be enabled manually through the configuration utility)

// default MAC address (6 bytes, comma separated)
// The last byte of the MAC address is replaced with the last byte of the IP address by the config utility,
// which allows the use of multiple DAN][ cards in a network.
#define FTP_MAC_ADDRESS 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED

// FTP ports: command port should normally be 21
#define FTP_CMD_PORT     21
// FTP data port can be any port. For "passive FTP" ports between 1024-65535 are used.
#define FTP_DATA_PORT    65020

// restrict FTP login to a specific user
// (Currently 7 bytes only and only upper case letters...
//  Will be improved and will be run-time configurable some day. For now, this has to do...)
//#define FTP_USER "DAN"

// restrict FTP login to a specific password (7 bytes only)
// (Currently 7 bytes only and only upper case letters...
//  Will be improved and will be run-time configurable some day. For now, this has to do...)
//#define FTP_PASSWORD "***"

/**********************************************************************************
 MISCELLANEOUS SETTINGS
 *********************************************************************************/
// Maximum number of VOLxx.PO files supported by FTP (16 for VOL00.PO - VOL0F.PO are enough)
#define FTP_MAX_VOL_FILES 16

// Enable/disable the use of the customized Ethernet library. This library saves a lot of
// space, removes some workarounds which are not needed for the DAN][ card. The customized
// library should normally be enabled. Otherwise the stock Arduino library is used - which
// should only be done for reference/comparisons.
// TBD: The customized lib is prepared, but not yet tested. So we keep it disabled for now...
#define FEATURE_CUSTOM_ETHERNET_LIBRARY

/* DAN][ configuration */

#define FW_VERSION "2.0.1"

#define USE_ETHERNET     // enable Ethernet support
#define USE_FTP          // enable FTP support
#undef USE_RAW_BLOCKDEV  // raw BLOCKDEV support (when disabled, "0" is handled as a normal volume file instead)
#undef USE_WIDEDEV       // wide device support

#undef USE_MEM_CHECK     // enable this for memory overflow checks
#undef DEBUG_SERIAL      // disable serial debug output

/* Select boot program:
  1=no boot program
  2=original/stock v2 bootprogram by DL Marks
  3=bootpg with improved GUI (512byte)
  4=bootpg with cursor key controls (1024byte)
  5=bootpg with mouse driver (TBD)
*/
#define BOOTPG 4

// default IPv4 address (4 bytes, comma separated)
#define FTP_IP_ADDRESS 192,168,1,65

// default MAC address (6 bytes, comma separated)
#define FTP_MAC_ADDRESS 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED

// FTP ports: command port should normally be 21
#define FTP_CMD_PORT     21
// FTP data port can be any port
#define FTP_DATA_PORT    20

// Maximum number of BLKDEVxx files supported by FTP (16/BLKDEV00-BLKDEV0F are enough)
#define FTP_MAX_BLKDEV_FILES 16

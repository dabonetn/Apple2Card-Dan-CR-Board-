/* DAN][ configuration */

#define FW_VERSION "2.0.0"

#define USE_ETHERNET // enable Ethernet support
#undef DEBUG_SERIAL  // disable serial debug output
#define USE_BLOCKDEV // BLOCKDEV support (when disabled, "0" is handled as a normal volume file instead)
#define USE_WIDEDEV  // wide device support

#undef USE_MEM_CHECK // enable this for memory overflow checks

/* Select boot program:
  1=no boot program
  2=original/stock v2 bootprogram by DL Marks
  3=bootpg with improved GUI (512byte)
  4=bootpg with cursor key controls (1024byte)
  5=bootpg with mouse driver (TBD)
*/
#define BOOTPG 4


/* ttftp.c - tiny tiny ftp. Seriously. Tiny.

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

#include "ttftp.h"
#include "config.h"
#include "fwversion.h"
#include "Apple2Arduino.h"
#include <Ethernet.h>

#ifdef USE_FTP

//#define FTP_DEBUG 1

#ifdef FTP_DEBUG
  #define FTP_DEBUG_PRINTLN(x) Serial.println(x)
#else
  #define FTP_DEBUG_PRINTLN(x) {}
#endif

/* size of the FTP data buffer on the stack (values >= 128 should work) */
#define FTP_BUF_SIZE          512

/* Timeout in milliseconds until clients have to connect to a passive connection */
#define FTP_PASV_TIMEOUT     3000

/* Timeout after which stale data connections are terminated. */
#define FTP_TRANSMIT_TIMEOUT 5000

/* Ethernet and MAC address ********************************************************************************/
// MAC+IP+Port address all packed into one compact data structure, to simplify configuration
byte FtpMacIpPortData[] = { FTP_MAC_ADDRESS, FTP_IP_ADDRESS, FTP_DATA_PORT>>8, FTP_DATA_PORT&0xff };
#define OFFSET_MAC 0
#define OFFSET_IP  6

/* Ethernet servers and clients ****************************************************************************/
EthernetServer FtpCmdServer(FTP_CMD_PORT);
EthernetServer FtpDataServer(FTP_DATA_PORT);
EthernetClient FtpCmdClient;
EthernetClient FtpDataClient;

/* Supported FTP commands **********************************************************************************/
/* FTP Command IDs*/
#define FTP_CMD_USER  0
#define FTP_CMD_SYST  1
#define FTP_CMD_CWD   2
#define FTP_CMD_TYPE  3
#define FTP_CMD_QUIT  4
#define FTP_CMD_PASV  5
#define FTP_CMD_LIST  6
#define FTP_CMD_CDUP  7
#define FTP_CMD_RETR  8
#define FTP_CMD_STOR  9
#define FTP_CMD_PWD  10

// offset of the PRODOS volume header
#define PRODOS_VOLUME_HEADER   0x400

/* Matching FTP Command strings (4byte per command) */
const char FtpCommandList[] PROGMEM = "USER" "SYST" "CWD " "TYPE" "QUIT" "PASV" "LIST" "CDUP" "RETR" "STOR" "PWD\x00";
                                       //"RNFR" "RNTO" "EPSV SIZE DELE MKD RMD"

/* Data types *********************************************************************************************/
typedef enum {DIR_SDCARD1=0, DIR_SDCARD2=1, DIR_ROOT=2} TFtpDirectory;
typedef enum {FTP_DISABLED=-1, FTP_NOT_INITIALIZED=0, FTP_INITIALIZED=1, FTP_CONNECTED=2} TFtpState;

//                                          "-rw------- 1 volume: 123456789abcdef 12345678 Jun 10 1977 VOL01.PO\r\n"
const char FILE_TEMPLATE[]        PROGMEM = "-rw------- 1 volume: ---             12345678 Jun 10 1977 VOL01.PO\r\n";
#define FILE_TEMPLATE_LENGTH      (sizeof(FILE_TEMPLATE)-1)

const char DIR_TEMPLATE[]         PROGMEM = "drwx------ 1 DAN][ FAT 1 Jun 10 1977 SD1\r\n";
#define DIR_TEMPLATE_LENGTH       (sizeof(DIR_TEMPLATE)-1)

const char ROOT_DIR_TEMPLATE[]    PROGMEM = "257 \"/SD1\"";
#define ROOT_DIR_TEMPLATE_LENGTH  (sizeof(ROOT_DIR_TEMPLATE)-1)

const char PASSIVE_MODE_REPLY[]   PROGMEM = "227 Entering Passive Mode (";

const char FTP_WELCOME[]          PROGMEM = "Welcome to DAN][, v" FW_VERSION ". Apple ][ Forever!";
const char FTP_NO_FILE[]          PROGMEM = "No such file/folder";
const char FTP_TOO_LARGE[]        PROGMEM = "File too large";
const char FTP_BAD_FILENAME[]     PROGMEM = "Bad filename";
const char FTP_FILE_ERR[]         PROGMEM = "I/O error";
const char FTP_DAN2[]             PROGMEM = "DAN][";
const char FTP_BYE[]              PROGMEM = "Bye.";
const char FTP_OK[]               PROGMEM = "Ok";
const char FTP_FAILED[]           PROGMEM = "Failed";

/* Local variables ****************************************************************************************/
// structure with local FTP variables
struct
{
  uint8_t CmdBytes;     // FTP command: current number of received command bytes
  uint8_t ParamBytes;   // FTP command: current number of received parameter bytes
  uint8_t CmdId;        // current FTP command
  uint8_t Directory;    // current working directory
  uint8_t _file[2];     // remembered original configuration
  char    CmdData[8];   // must just be large enough to hold file names (just for the first 8 bytes of 8.3 filenames)
} Ftp;

int8_t  FtpState = FTP_NOT_INITIALIZED;

extern int __heap_start, *__brkval;

#if 1
  void FTP_CMD_REPLY(char* buf, uint16_t sz) {buf[sz] = '\r';buf[sz+1]='\n';FtpCmdClient.write(buf, sz+2);}
#else
  void FTP_CMD_REPLY(char* buf, uint16_t sz)  {buf[sz] = '\r';buf[sz+1]='\n';FtpCmdClient.write(buf, sz+2);Serial.write(buf, sz+2);}
#endif

// simple string compare - avoiding more expensive compare in stdlib
bool strMatch(const char* str1, const char* str2)
{
  do
  {
    if (*str1 != *(str2++))
      return false;
  } while (*(str1++)!=0);
  return true;
}

// copy a string from PROGMEM to a RAM buffer
uint8_t strReadProgMem(char* buf, const char* pProgMem)
{
  uint8_t sz=0;
  do
  {
    *buf = pgm_read_byte_near(pProgMem++);
    sz++;
  } while (*(buf++));
  return sz-1;
}

// map FTP command string to ID
int8_t ftpGetCmdId(char* buf, const char* command)
{
  uint32_t cmd = *((uint32_t*) command);
  int8_t CmdId = 0;
  strReadProgMem(buf, FtpCommandList);
  while (buf[CmdId] != 0)
  {
    if (cmd == *((uint32_t*) &buf[CmdId]))
      return (CmdId >> 2);
    CmdId += 4;
  }
  return -1;
}

char* strPrintInt(char* pStr, uint32_t data, uint32_t maxDigit=10000, char fillByte=0)
{
  uint32_t d = maxDigit;
  uint8_t i=0;
  bool HaveDigits = false;
  while (d>0)
  {
    uint8_t c = data/d;
    if ((c>0)||(HaveDigits)||(d==1))
    {
      if (c>9)
        c=9;
      pStr[i++] = '0'+c;
      data = data % d;
      HaveDigits = true;
    }
    else
    if (fillByte)
    {
      pStr[i++] = fillByte;
    }
    d /= 10;
  }
  return &pStr[i];
}

void ftpSendReply(char* buf, uint16_t code)
{
  // set three-digit reply code
  strPrintInt(buf, code, 100, '0');
  buf[3] = ' ';

  // append plain message
  const char* msg;
  switch(code)
  {
    case 215: msg = FTP_DAN2;break;
    case 220: msg = FTP_WELCOME;break;
    case 221: msg = FTP_BYE;break;
    case 451: msg = FTP_FILE_ERR;break;
    case 550: msg = FTP_NO_FILE;break;
    case 552: msg = FTP_TOO_LARGE;break;
    case 553: msg = FTP_BAD_FILENAME;break;
    default:
      msg = (code<=399) ? FTP_OK : FTP_FAILED;
  }

  uint8_t sz = 4;
  sz += strReadProgMem(&buf[sz], msg);
#ifdef DEBUG_BYTES
  // Output some DEBUG bytes by appending it to the FTP welcome messaage.
  // Enables obtaining simple debugging bytes through the Ethernet/FTP connection.
  if (code == 220)
  {
    for (uint8_t i=0;(i<DEBUG_counter)&&(i<DEBUG_BYTES);i++)
    {
      buf[sz++] = hex_digit(DEBUG_data[i]>>4);
      buf[sz++] = hex_digit(DEBUG_data[i]&0xf);
    }
  }
#endif
  FTP_CMD_REPLY(buf, sz);
}

// wait and accept for an incomming data connection
bool ftpAcceptDataConnection(bool Cleanup=false)
{
  uint16_t Timeout = (Cleanup) ? 10 : FTP_PASV_TIMEOUT;
  for (uint16_t i=0;i<Timeout;i++)
  {
    FtpDataClient = FtpDataServer.accept();
    if (FtpDataClient.connected())
    {
      FTP_DEBUG_PRINTLN(F("new"));
      if (Cleanup)
        FtpDataClient.stop();
      else
        FtpDataClient.setConnectionTimeout(5000);
      return true;
    }
    delay(1);
  }
  return false;
}

bool ftpSelectFile(uint8_t fileno, uint32_t* pFileBlockCount)
{
  if (Ftp.Directory == DIR_ROOT)
    return false;

  request.sdslot  = Ftp.Directory;
  request.filenum = fileno;
  CHECK_MEM(1010);

  if (!vol_open_drive_file())
    return false;

  uint32_t FileBlockCount = 0;
  if (slot_type[request.sdslot] == SLOT_TYPE_RAW)
    FileBlockCount = 65536; // fixed maximum volume size
  else
    FileBlockCount = (f_size(&current_file) >> 9); // size of the DOS file
  if (FileBlockCount > 65536)
    FileBlockCount = 65536;
  *pFileBlockCount = FileBlockCount;

  return true;
}

static void file_seek(uint32_t blknum)
{
  request.blk = blknum;
}

// obtains volume name and block count
uint32_t getProdosVolumeInfo(uint8_t* ProdosHeader, char* pVolName, uint32_t FileBlocks)
{
  // read PRODOS volume name from header
  file_seek(PRODOS_VOLUME_HEADER>>9);
  if (0==vol_read_block(ProdosHeader))
  {
    uint8_t len = ProdosHeader[4] ^ 0xf0; // top 4 bits must be set for PRODOS volume name lengths
    uint16_t ProdosDirLenEntry = *((uint16_t*)&ProdosHeader[0x23]);

    if ((ProdosDirLenEntry == 0x0D27)&& // check entry length/entries per block=$27/$0D
        (len <= 0xf))                   // valid length field?
    {
      // write 15 ASCII characters with PRODOS volume name
      if (pVolName)
      {
        for (uint8_t i=0;i<15;i++)
        {
          char ascii = ProdosHeader[5+i];
          if ((i>=len)||(ascii<' ')||(ascii>'z'))
            ascii=' ';
          pVolName[i] = ascii;
        }
      }

      // get PRODOS volume size
      uint16_t ProdosBlocks = ProdosHeader[0x2A];
      ProdosBlocks <<= 8;
      ProdosBlocks |= ProdosHeader[0x29];
      // report PRODOS volume size (unless physical block device file is smaller)
      if (ProdosBlocks < FileBlocks)
        FileBlocks = ProdosBlocks;
    }
  }
  else
  if ((pVolName)&&(slot_type[request.sdslot] == SLOT_TYPE_FAT))
    pVolName[0] = 0; // FAT file is unreadable/corrupt

  return FileBlocks;
}

void ftpHandleDirectory(char* buf)
{
  if (Ftp.Directory == DIR_ROOT)
  {
    strReadProgMem(buf, DIR_TEMPLATE);                       // get template for "SD1"
    strReadProgMem(&buf[DIR_TEMPLATE_LENGTH], DIR_TEMPLATE); // get template for "SD2"

    uint8_t pos = 0;
    for (uint8_t slot=0;slot<2;slot++)
    {
      if (slot_type[slot] > SLOT_TYPE_UNKNOWN)
      {
        if (slot_type[slot] == SLOT_TYPE_RAW)
        {
          buf[pos+19] = 'R';
          buf[pos+20] = 'A';
          buf[pos+21] = 'W';
        }
        pos += DIR_TEMPLATE_LENGTH;
        if (slot==1)
          buf[pos-2-1] = '2'; // patch '1'=>'2' for SD2
      }
    }
    FtpDataClient.write(buf, pos);
  }
  else
  {
    // iterate over possible file names: VOLXX.PO
    for (uint8_t fno=0;fno<FTP_MAX_VOL_FILES;fno++)
    {
      uint32_t FileBlocks;
      if (ftpSelectFile(fno, &FileBlocks))
      {
        // read PRODOS volume name from header
        char VolName[16];
        for (uint8_t i=0;i<16;i++) VolName[i] = ' ';
        FileBlocks = getProdosVolumeInfo((uint8_t*) buf, VolName, FileBlocks);

        if (VolName[0])
        {
          strReadProgMem(buf, FILE_TEMPLATE);

          buf[FILE_TEMPLATE_LENGTH-7] = hex_digit(fno>>4);
          buf[FILE_TEMPLATE_LENGTH-6] = hex_digit(fno);

          // update volume name
          memcpy(&buf[21], VolName, 15);

          // update file size
          strPrintInt(&buf[37], FileBlocks<<9, 10000000, ' ');

          // send directory entry
          FtpDataClient.write(buf, FILE_TEMPLATE_LENGTH);
        }
      }
    }
  }
}

// receive or send file data: return FTP reply code
uint16_t ftpHandleFileData(char* buf, uint8_t fileno, bool Read)
{
  uint32_t FileBlocks;
  if (!ftpSelectFile(fileno, &FileBlocks))
  {
    FTP_DEBUG_PRINTLN(F("nofile"));
    return 550;
  }

  uint32_t blknum = 0;
  if (Read)
  {
    // obtain ProDOS file size for reading
    FileBlocks = getProdosVolumeInfo((uint8_t*) buf, NULL, FileBlocks);
    // read from disk and send to remote
    // we only send the data for the ProDOS drive - the physical VOLxx.PO file may be larger...
    while (blknum < FileBlocks)
    {
      file_seek(blknum);
      if (vol_read_block(buf) != PRODOS_OK)
        return 451; // I/O error
      blknum++;
      CHECK_MEM(1020);
      if (FtpDataClient.write(buf, 512) != 512)
      {
        return 426; // failed, connection aborted...
      }
    }
  }
  else
  {
    // receive remote data and write to disk
    uint16_t TcpBytes=0;
    uint16_t BufOffset=0;
    long Timeout = 0;

    while ((Timeout == 0)||(((long) (millis()-Timeout))<0))
    {
      if (TcpBytes == 0)
      {
        mmc_wait_busy_spi(); // check recent f_write is completed/SPI released
        TcpBytes = FtpDataClient.available();
        if (TcpBytes == 0)
        {
          if (!FtpDataClient.connected())
          {
            FTP_DEBUG_PRINTLN(F("discon"));
            FTP_DEBUG_PRINTLN(FtpDataClient.status());
            CHECK_MEM(1030);
            break;
          }
        }
      }
      while (TcpBytes)
      {
        mmc_wait_busy_spi(); // check recent f_write is completed/SPI released
        size_t sz = (BufOffset+TcpBytes > FTP_BUF_SIZE) ? FTP_BUF_SIZE-BufOffset : TcpBytes;
        int rd = FtpDataClient.read((uint8_t*) &buf[BufOffset], sz);
        CHECK_MEM(1040);
        if (rd>0)
        {
          // reset timeout when data was received
          Timeout = 0;

          BufOffset += rd;
          TcpBytes-=rd;
          if (BufOffset >= FTP_BUF_SIZE)
          {
            if (blknum >= FileBlocks)
              return 552; // file too large

            // write block to disk
            file_seek(blknum);
            if (vol_write_block(buf) != PRODOS_OK)
            {
              FTP_DEBUG_PRINTLN(F("badwr"));
              return 451; // I/O error
            }
            blknum++;
            BufOffset = 0;
          }
        }
      }
      // calculate new timeout when necessary
      if (!Timeout)
      {
        Timeout = millis()+FTP_TRANSMIT_TIMEOUT;
      }
    }
    if (BufOffset>0)
    {
      if (blknum >= FileBlocks)
        return 552; // file too large
      file_seek(blknum);
      if (vol_write_block(buf) != PRODOS_OK)
      {
        return 451; // I/O error
      }
    }
  }
  return 226; // file transfer successful
}

// check the requested file name - and get the volume file number
uint8_t getVolFileNo(char* Data)
{
  uint8_t digit = Data[3]; // get the first digit
  Data[3] = 0; // only check the first 3 bytes

  if (!strMatch(Data, "VOL"))
  {
    return 255;
  }

  uint8_t fno = 0;
  for (uint8_t i=0;i<2;i++)
  {
    fno <<= 4;
    if ((digit>='0')&&(digit<='9'))
      digit -= '0';
    else
    if ((digit>='A')&&(digit<='F'))
      digit -= 'A'-10;
    else
      return 255; // invalid file number
    fno |= digit;
    digit = Data[4]; // get the next/lower digit
  }

  return fno;
}

// simple command processing
void ftpCommand(char* buf, int8_t CmdId, char* Data)
{
  uint16_t ReplyCode = 0;
  CHECK_MEM(1100);
  switch(CmdId)
  {
    case FTP_CMD_USER: ReplyCode = 230; break; // Logged in.
    case FTP_CMD_SYST: ReplyCode = 215; break; // Report sys name
    case FTP_CMD_CWD:
      // change directory: we only support the root directory and SD1+SD2
      ReplyCode = 250; // file action OK
      if ((strMatch(Data, ".."))||(strMatch(Data, "/")))
        Ftp.Directory = DIR_ROOT;
      else
      {
        if (Data[0]=='/')
          Data++;
        if (strMatch(Data, "SD1"))
          Ftp.Directory = DIR_SDCARD1;
        else
        if (strMatch(Data, "SD2"))
          Ftp.Directory = DIR_SDCARD2;
        else
          ReplyCode = 550; // directory 'not found'...
      }
      break;
    case FTP_CMD_TYPE: ReplyCode = 200; break;
    case FTP_CMD_QUIT: ReplyCode = 221; break; // Bye.
    case FTP_CMD_PASV:
    {
      // sometimes, after commands have failed, we need to clean-up pending connections...
      while (ftpAcceptDataConnection(true));
      uint8_t sz = strReadProgMem(buf, PASSIVE_MODE_REPLY);
      char* s = &buf[sz];
      for (uint8_t i=0;i<6;i++)
      {
      if (i>0)
        *(s++) = ',';
      s = strPrintInt(s, FtpMacIpPortData[OFFSET_IP+i], 100, 0);
      }
      *(s++) = ')';
      FTP_CMD_REPLY(buf, (s-buf));
      break;
    }
    case FTP_CMD_LIST:
    case FTP_CMD_RETR:
    case FTP_CMD_STOR:
    {
      ftpSendReply(buf, 150);
      if (!ftpAcceptDataConnection())
      {
        ReplyCode = 425; // Can't open data connection.
      }
      else
      {
        if (CmdId == FTP_CMD_LIST)
        {
          ftpHandleDirectory(buf);
          ReplyCode = 226; // Listed.
        }
        else
        {
          uint8_t fno = getVolFileNo(Data);
          if (fno >= FTP_MAX_VOL_FILES)
            ReplyCode = 553; // file name not allowed
          else
          {
            ReplyCode = ftpHandleFileData(buf, fno, (CmdId == FTP_CMD_RETR));
            mmc_wait_busy_spi(); // check f_write is completed/SPI released
          }
        }
        delay(10);
        FtpDataClient.stop();
      }
      break;
    }
    case FTP_CMD_CDUP:
      Ftp.Directory = DIR_ROOT;
      ReplyCode = 250; // Went to parent folder.
      break;
    case FTP_CMD_PWD:
    {
      strReadProgMem(buf, ROOT_DIR_TEMPLATE);
      if (Ftp.Directory == DIR_ROOT)
      {
        buf[6] = '\"';
        FTP_CMD_REPLY(buf, 7);
      }
      else
      {
        if (Ftp.Directory == DIR_SDCARD2)
          buf[ROOT_DIR_TEMPLATE_LENGTH-2] = '2';
        FTP_CMD_REPLY(buf, ROOT_DIR_TEMPLATE_LENGTH);
      }
      break;
    }
    default:
      ReplyCode = 502; // Unsupported command.
      break;
  }
  if (ReplyCode)
    ftpSendReply(buf, ReplyCode);
}

static void ftpInit()
{
  // IP address "0" disables the FTP server and Eth initialization completely
  if (FtpMacIpPortData[OFFSET_IP]==0)
  {
    FtpState = FTP_DISABLED;
    return;
  }

  Ethernet.init(D_CS3); // used arduino 'digital' pin number here

#ifdef FTP_DEBUG
  Serial.begin(115200);
  FTP_DEBUG_PRINTLN(F("TinyTinyFTP"));
#endif

  // obtain IP address from the data structure
  IPAddress Ip(FtpMacIpPortData[OFFSET_IP],FtpMacIpPortData[OFFSET_IP+1],FtpMacIpPortData[OFFSET_IP+2],FtpMacIpPortData[OFFSET_IP+3]);

  Ethernet.begin(&FtpMacIpPortData[OFFSET_MAC], Ip);

  if (Ethernet.hardwareStatus() == EthernetNoHardware)
  {
    FTP_DEBUG_PRINTLN(F("Wiz5500 not found"));
    // no hardware: keep this module disabled
    FtpState = FTP_DISABLED;
    return;
  }

#if 0 // this is not necessary - and prevents usecases where the cable is plugged later (or the remote port is still sleeping)
  if (Ethernet.linkStatus() == LinkOFF)
  {
    FTP_DEBUG_PRINTLN(F("Eth cable not connected"));
    // hardware but no connected cable: keep this module disabled
    FtpState = FTP_DISABLED;
    return;
  }
#endif

  // start the servers
  FtpCmdServer.begin();
  FtpDataServer.begin();

#ifdef FTP_DEBUG
  FTP_DEBUG_PRINTLN(Ethernet.localIP());
#endif

  FtpState = FTP_INITIALIZED;
}

// FTP processing loop
void loopTinyFtp(void)
{
  char buf[FTP_BUF_SIZE];
  static int Throttle = 2000; // first FTP communication attempt after 2seconds (Wiznet is slower than Arduino)

  if ((FtpState < 0)||
      ((Throttle != 0)&&((int) (millis()-Throttle) < 0)))
  {
    return;
  }

  // before talking to WIZnet, make sure the SPI bus is not blocked by a pending write
  mmc_wait_busy_spi();

  if (FtpState == FTP_NOT_INITIALIZED)
  {
    ftpInit();
  }

  do
  {
    if (FtpState == FTP_INITIALIZED) // initialized but not connected
    {
      // accept incomming command connection
      FtpCmdClient = FtpCmdServer.accept();
      if (FtpCmdClient.connected())
      {
        FTP_DEBUG_PRINTLN(F("FTP con"));
        FtpState  = FTP_CONNECTED;
        // FTP welcome
        ftpSendReply(buf, 220);
        // expect new command
        Ftp.CmdBytes = 0;
        // always start in root directory
        Ftp.Directory = DIR_ROOT;
      }
    }
    else
    if (FtpState == FTP_CONNECTED)
    {
      if (!FtpCmdClient.connected())
      {
        FTP_DEBUG_PRINTLN(F("FTP dis"));
        // give the remote client time to receive the data
        delay(10);
        FtpCmdClient.stop();
        FtpState = FTP_INITIALIZED;
      }
      else
      if (FtpCmdClient.available())
      {
        char c = FtpCmdClient.read();
        // Convert everything to upper case. So both, lower+upper case commands/filenames work.
        if ((c>='a')&&(c<='z'))
          c+='A'-'a';
        if (c == '\r')
        {
          // ignored
        }
        else
        if (Ftp.CmdBytes < 4) // FTP command length has a maximum of 4 bytes
        {
          Ftp.CmdData[Ftp.CmdBytes++] = (c=='\n') ? 0 : c;
          Ftp.CmdData[Ftp.CmdBytes] = 0;
          if ((c == '\n')||(Ftp.CmdBytes == 4))
            Ftp.CmdId = ftpGetCmdId(buf, Ftp.CmdData);
          if (c == '\n')
          {
            // execute command with no paramters
            ftpCommand(buf, Ftp.CmdId, "");
            Ftp.CmdBytes = 0;
          }
          Ftp.ParamBytes = 0;
        }
        else
        {
          // process FTP command parameter
          if (c==' ')
          {
            // ignored
          }
          else
          if (c == '\n')
          {
            // command & parameter is complete
            Ftp.CmdData[Ftp.ParamBytes] = 0;
            ftpCommand(buf, Ftp.CmdId, Ftp.CmdData);
            Ftp.CmdBytes = 0;
            Ftp.ParamBytes = 0;
          }
          else
          if (Ftp.ParamBytes < sizeof(Ftp.CmdData)-1)
          {
              Ftp.CmdData[Ftp.ParamBytes++] = c;
          }
        }
      }
    }
    CHECK_MEM(1001);

  } while (FtpState == FTP_CONNECTED);

  // check every 100ms for incomming FTP connections
  Throttle = millis()+100;
}

#endif // USE_FTP

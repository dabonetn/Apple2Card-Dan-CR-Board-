/* ttftp.h - tiny tiny ftp. Seriously. Tiny.

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
#pragma once

typedef enum {FTP_DISABLED=-1, FTP_NOT_INITIALIZED=0, FTP_INITIALIZED=1, FTP_CONNECTED=2} TFtpState;

extern byte   FtpMacIpPortData[]; // 6 bytes MAC address, 4 bytes IPv4 address
extern int8_t FtpState;

#ifdef __cplusplus
extern "C"
{
#endif

  void loopTinyFtp(void);

#ifdef __cplusplus
}
#endif

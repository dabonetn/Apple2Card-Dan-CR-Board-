/* pindefs.h */
/* by Daniel L. Marks */

/*
 * Copyright (c) 2022 Daniel Marks

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

#ifndef _PINDEFS_H
#define _PINDEFS_H

#define DAN_328P  3
#define DAN_644P  4

#if defined(__AVR_ATmega328P__)
#define CS     2    // PB2
#define CS2    1     // PB1
#define CS3    0     // PB0
#define D_CS3  8     // PB0 in Arduino Digital pin

#define MOSI   3    // PB3
#define MISO   4    // PB4
#define SCK    5    // PB5

#define STBA   0  // PC0
#define IBFA   1  // PC1
#define ACKA   2  // PC2
#define OBFA   3  // PC3
#define DAN_CARD     DAN_328P
#elif defined(__AVR_ATmega644P__)
#define CS     2     // PB2
#define CS2    1     // PB1
#define CS3    0     // PB0
#define D_CS3  8     // PB0 in Arduino Digital pin

#define MOSI   5    // PB5
#define MISO   6    // PB6
#define SCK    7    // PB7
#define SLAVE_S 4   // PB4 SS PIN *needs* to be configured as it's floating!

#define STBA   6  // PC6
#define IBFA   7  // PC7
#define ACKA   2  // PC2
#define OBFA   3  // PC3
#define DAN_CARD     DAN_644P
#else
#error Invalid platform for pindef.h!
#endif

#define SOFTWARE_SERIAL
#define SOFTWARE_SERIAL_RX A4
#define SOFTWARE_SERIAL_TX A5

#define CS_ALL			(_BV(CS)|_BV(CS2)|_BV(CS3))
/* Make sure we never use PORTB = XXX as it nukes settings for the SS pin */
#define DISABLE_CS() do { PORTB |= CS_ALL; DDRB |= CS_ALL; } while (0)
#define DISABLE_RXTX_PINS() UCSR0B &= ~(_BV(RXEN0)|_BV(TXEN0)|_BV(RXCIE0)|_BV(UDRIE0))
#define ENABLE_RXTX_PINS() UCSR0B |= (_BV(RXEN0)|_BV(TXEN0)|_BV(RXCIE0)|_BV(UDRIE0))
#define WAIT_TX() while ((UCSR0A & _BV(TXC0) == 0)

#define DATAPORT_MODE_TRANS() DDRD = 0xFF
#define DATAPORT_MODE_RECEIVE() do { PORTD = 0x00; DDRD = 0x00; } while (0)

#define READ_DATAPORT() (PIND)
#define WRITE_DATAPORT(x) do { uint8_t temp = (x); PORTD=temp; PORTD=temp; } while (0)

#define READ_OBFA() (PINC & _BV(OBFA))
#define READ_IBFA() (PINC & _BV(IBFA))
#define ACK_LOW_SINGLE() PORTC &= ~_BV(ACKA)
#define ACK_HIGH_SINGLE() PORTC |= _BV(ACKA)
#define STB_LOW_SINGLE() PORTC &= ~_BV(STBA)
#define STB_HIGH_SINGLE() PORTC |= _BV(STBA)

/* Needed to slow down data send for 82C55 */

// Ack has to be 200ns -- 16mhz AVR cycle is ~63
// ACK to data available is 175ns, so 3 cycles of ACK low should be enough
#define ACK_LOW() do { \
                     ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); \
                     ACK_LOW_SINGLE(); ACK_LOW_SINGLE(); \
                  } while (0)
// the read operation should be one cycle, so we reach 200ns and we can release ACK immediately
#define ACK_HIGH() do { ACK_HIGH_SINGLE();  } while (0)
// STB to IBS is 150ns, that's 3 AVR cycles, however, we don't /need/ to wait, we could just read IBS
#define STB_LOW() do { \
                        STB_LOW_SINGLE(); STB_LOW_SINGLE(); STB_LOW_SINGLE(); \
                        STB_LOW_SINGLE(); STB_LOW_SINGLE();\
                  } while (0)
#define STB_HIGH() do { STB_HIGH_SINGLE(); } while (0)

#define INITIALIZE_CONTROL_PORT() do { \
  PORTC |= (_BV(STBA) | _BV(IBFA) | _BV(ACKA) | _BV(OBFA)); \
  DDRC |= (_BV(STBA) | _BV(ACKA)); \
  DDRC &= ~(_BV(IBFA) | _BV(OBFA)); \
  PORTC |= (_BV(STBA) | _BV(IBFA) | _BV(ACKA) | _BV(OBFA)); \
} while (0)

#endif /* _PINDEFS_H */

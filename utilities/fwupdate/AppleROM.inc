; Copyright 2023 Thorsten C. Brehm

.IFDEF APPLE3

; Apple III ROM routines
BELL       = $FC4E
HOME       = $FB7D ; Apple III screen init routine
PRHEX      = $F9B7
PRBYTE     = $F941
RDKEY      = $FD0C
KEYIN      = $FD0F
SETCV      = $FBC5
COUT       = $FC39
VTAB       = $FBC7 ; Apple III BASCALC routine to calculate line's base address
MONITOR    = $F901
COUT2      = $FC06
COL40      = $FB63
VBOUNDS    = $FFB8
HOOKS      = $FFB4

; APPLE III ROM registers
SCRNLOC    = $58
LMARGIN    = SCRNLOC
RMARGIN    = SCRNLOC+1
WINTOP     = SCRNLOC+2
WINBTM     = SCRNLOC+3
CH         = SCRNLOC+4   ; horizontal cursor position (column)
CV         = SCRNLOC+5   ; vertical cursor position (row)
BAS4L      = SCRNLOC+6
BAS4H      = SCRNLOC+7
BAS8L      = SCRNLOC+8
BAS8H      = SCRNLOC+9
FORGND     = SCRNLOC+$0E
BKGND      = SCRNLOC+$0F
MODES      = SCRNLOC+$10 ; bit 0x80 for inverse (1=normal, 0=inverse), 0x40 for 40 vs 80char mode (1=80 chars)
CURSOR     = SCRNLOC+$11
CSWL       = SCRNLOC+$16
CSWH       = SCRNLOC+$17
KSWL       = SCRNLOC+$18
KSWH       = SCRNLOC+$19

BASL       = BAS4L       ; APPLE II to III mapping for 40 column mode
BASH       = BAS4H

.ELSE

; APPLE II ROM subroutines
BELL     = $FBE2
HOME     = $FC58
PRHEX    = $FDE3
PRBYTE   = $FDDA
RDKEY    = $FD0C
COUT     = $FDED
VTAB     = $FC22
WAITLOOP = $FCA8
MONITOR  = $FF69

; APPLE II ROM registers
CH       = $24   ; horizontal cursor position (column)
CV       = $25   ; vertical cursor position (row)
BASL     = $28
BASH     = $29

.ENDIF

; generate Apple-ASCII string (with MSB set)
.MACRO   ASCHI STR
      .REPEAT  .STRLEN (STR), C
       .BYTE    .STRAT (STR, C) | $80
      .ENDREP
.ENDMACRO

; generated string with inverted characters
.MACRO   ASCINV STR
      .REPEAT  .STRLEN (STR), C
   .IFDEF APPLE3
       .BYTE    .STRAT (STR, C)
   .ELSE
       .BYTE    .STRAT (STR, C) & $3F
   .ENDIF
      .ENDREP
.ENDMACRO


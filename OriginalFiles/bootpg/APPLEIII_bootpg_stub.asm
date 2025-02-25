; Stub for Apple III boot program
; Copyright 2023 T. C. Brehm
;
; The Apple III boot program is loaded from a file (unlike for the Apple II, where
; the bootpg is embedded in the Arduino firmware). However, when the file is missing
; on the SD card, we at least provide a tiny stub, so the Apple III is able to show
; an error message, explaining the missing file.

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

; generate Apple-ASCII string (with MSB set)
.MACRO ASCHI STR
      .REPEAT  .STRLEN (STR), C
       .BYTE    .STRAT (STR, C) | $80
      .ENDREP
.ENDMACRO

         .ORG $A000      ; Apple III bootloaders are loaded to this address

START:
         NOP
         LDX #$FF
:        INX
         LDA MSG,X
         BEQ DONE
         JSR COUT
         BNE :-          ; unconditional branch (A!=0)
DONE:    JSR BELL
END:     JMP MONITOR

MSG:
         ASCHI "DANII: NO VOLA3.PO!"
         .BYTE $8D,0

BOOT_END:

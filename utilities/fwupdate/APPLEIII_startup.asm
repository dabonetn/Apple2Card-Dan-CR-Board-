; DAN][ controller Arduino firmware update utility: Apple III SOS startup.
;
; Copyright (c) 2023 Thorsten C. Brehm
;
;  This software is provided 'as-is', without any express or implied
;  warranty. In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.

; imported data labels
.import FW_END

; imported code labels
.import MAIN
.import DAN2_FWUPDATE

; exported code labels
.export CLEAR_WARMSTART
.export SET_WARMSTART

.setcpu "6502"

; include ROM routines for Apple II or III
.include "AppleROM.inc"

; The syntax for a SOS call using the macro below is
; SOS     call_num, parameter_list pointer
.MACRO  SOS CALL,PARAM  ; Macro def for SOS call block
BRK                     ; Begin SOS call block
.BYTE   CALL            ; call_num
.WORD   PARAM           ; parameter_list pointer
.ENDMACRO               ; end of macro definition

; APPLE3 SYSTEM REGISTERS
ENVREG      = $FFDF ; Environment Register (bits: 0:ROMEN,1:ROM1,2:PRSTK,3:WPROT,4:RSTEN,5:SCRN,6:IOEN,7:1MHz)
SYSE3       = $FFE3 ; DDR register for BANKREG
BANKREG     = $FFEF ; Bank selection register for $2000-$9FFF (lower 4 bits)

; ZERO PAGE VARS
POINTER       = $90
POINTERHIGH   = $91
ENVTEMP       = $92

;
; Interpreter Header
;
CODE_AREA        = $2000
CODESTART        = CODE_AREA
CODELEN          = FW_END-CODESTART; Calculate number of bytes in

;          .ORG     CODESTART-$0E; Leave 14 bytes for header

; SOS EXECUTABLE HEADER
.SEGMENT "SOSHEADER"
.export SOS_EXE_HEADER
SOS_EXE_HEADER:
          .BYTE    "SOS NTRP"   ; 8 bytes, fixed label for SOS.INTERP
          .WORD    $0000        ; 2 bytes, opt_header_length = 0 (if >0, then additional data follows this element)
          .WORD    CODESTART    ; 2 bytes, loading_address
          .WORD    CODELEN      ; 2 bytes, code_length, size of program without header
                                ; Interpreters are always ABSOLUTE code, starting at a fixed location.
.SEGMENT "CODE"
           JMP     BEGIN        ; Jump to beginning of code

.WORD BEGIN
.export BEGIN
BEGIN:
           SEI                 ; block interrupts
           LDA     ENVREG      ; get environment
	   STA     ENVTEMP     ; save environment
           ORA     #$F3        ; enable IO access+ROM+1MHz
           STA     ENVREG

           ; copy ROM's screen routine init data to ZERO page
           LDX     #$03
SETUP1:    LDA     VBOUNDS,X
           STA     LMARGIN,X
           LDA     HOOKS,X
           STA     CSWL,X
           DEX
           BPL     SETUP1

           ; enable 40column mode, non-inverse mode
           LDA     #$FF
           STA     MODES
           JSR     COL40
           LDA     #'_'+$80
           STA     CURSOR
           
           ; call fw update main
           JSR     MAIN

           ; we cannot exit to SOS after enabling the A2 Emulation Switch
           ; (irreversible, requires full system-reset)
           LDA     A2MODE
           BNE     STOP
TERMINATE:
           LDA     ENVTEMP     ; restore environment settings
           STA     ENVREG
           CLI                 ; restore interrupts
           ; SOS TERMINATE call
           SOS     $65,BYEPARM
BYEPARM:   .BYTE   0        ; must be 0

A2MODE:    .BYTE $00  ; flag indicating if we have enabled the A2SW switch

WARMSTART:
           JMP     DAN2_FWUPDATE

CLEAR_WARMSTART:
           ; redirect NMI to endless loop
           LDA     #<STOP
           STA     $FFFA
           LDA     #>STOP
           STA     $FFFB
           RTS

           ; we cannot exit to SOS after enabling the AIISW (Apple II Emulation mode).
           ; All we can do is lock and wait for a hardware reset.
STOP:      JMP     STOP

SET_WARMSTART:
           ; copy ROM to RAM area
           JSR     COPYROM

           ; set NMI vector
           LDA     #<WARMSTART; redirect NMI to WARMSTART
           STA     $FFFA
           LDA     #>WARMSTART
           STA     $FFFB

           LDA     #$01
           STA     A2MODE
           LDA     BANKREG
           AND     #$BF       ; set /AIISW=0
           STA     BANKREG
           LDA     #$4F
           STA     SYSE3      ; set data direction register, enable AIISW output
           LDA     $C051      ; ensure we're still in 40column text mode
           LDA     $C054      ; page 1
           RTS

; copy APPLE III ROM to RAM overlay
COPYROM:   LDA #$00         ; start copying at address $F000
           STA POINTER
           LDA #$F0
           STA POINTER+1
COPYMORE:
           LDA ENVREG       ; load environment register
           ORA #$03         ; now enable ROM, disable RAM overlay
           STA ENVREG       ; enable ROM space and ROM page 1
           LDY #$00
READPAGE:  LDA (POINTER),Y  ; read from ROM
           STA COPYBUF,Y    ; write to buffer
           INY              ; next page
           BNE READPAGE     ; until complete 256byte page is copied

           LDA ENVREG       ; load environment register
           AND #$F4         ; now disable ROM, access RAM overlay instead
           STA ENVREG       ; enable RAM space
WRITEPAGE: LDA COPYBUF,Y    ; read from buffer
           STA (POINTER),Y  ; write to RAM overlay
           INY              ; next byte
           BNE WRITEPAGE    ; until complete 256byte page is copied

           INC POINTER+1    ; next ROM 256byte page 
           BNE COPYMORE     ; keep copying until we're done
           RTS

; 256 byte intermediate buffer area when we copy the ROM page by page
COPYBUF: 
           .REPEAT 256
           .BYTE 0
           .ENDREP


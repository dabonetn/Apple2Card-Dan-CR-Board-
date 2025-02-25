; DAN][ controller Arduino firmware update utility: main program.
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

.setcpu "6502"

; include ROM routines for Apple II or III
.include "AppleROM.inc"

; import interface functions
.import CLEAR_WARMSTART
.import SET_WARMSTART
.import print
.import MSG_ADDR
.import SLOTNUM

; temp variables
danx    = $43  ; X register value for accessing the DAN controller
buflo   = $44  ; low address of buffer
bufhi   = $45  ; hi address of buffer
adrlo   = $46  ; lower flash word address
adrhi   = $47  ; upper flash word address

.MACRO   PRINT STRVAR
    LDA #<STRVAR      ; use full 16bit address, since string resource has
    STA MSG_ADDR      ; outgrown 256 bytes...
    LDA #>STRVAR
    STA MSG_ADDR+1
    JSR print
.ENDMACRO

 ; code is relocatable
.segment	"CODE"

; main UPDATE utility
.export MAIN
MAIN:
    PRINT(MSG_WELCOME)

    JSR askSlotNumber   ; ask which slot number to use
    LDA SLOTNUM
    BEQ abort

    PRINT(MSG_PRESS_START)
    JSR SET_WARMSTART
    JSR RDKEY           ; wait for keypress - or CTRL-RESET
    JSR CLEAR_WARMSTART

abort:
    PRINT(MSG_ABORTED)
    RTS

; ask user about which slot to use (multiple cards might be plugged :) )
askSlotNumber:
    LDA #$00
    STA SLOTNUM
    PRINT(MSG_ASK_SLOT)
    JSR RDKEY
    PHA
    JSR COUT            ; print user input character to screen
    LDA #13+128
    JSR COUT
    PLA
    CMP #27+128         ; escape key?
    BNE :+              ; no escape?
    RTS                 ; escape=>abort
:   CMP #'1'+128        ; <1 ?
    BMI slot_bad        ; branch when < 1
.IFDEF APPLE3
    CMP #'5'+128        ; >=5 ?
.ELSE
    CMP #'8'+128        ; >=8 ?
.ENDIF
    BPL slot_bad        ; branch when >= 8
    AND #$0F            ; convert slot number (1-7) to number
    STA SLOTNUM
    JSR checkDanSlot    ; is there really a DANII card in this slot?
    BEQ slot_ok
    PRINT(MSG_NO_DANII) ; no card detected
    LDA SLOTNUM         ; show slot number
    ORA #'0'+128
    JSR COUT
    JSR BELL
    JMP askSlotNumber   ; ask again
slot_ok:
    RTS
slot_bad:
    PRINT(MSG_INVALID_SLOT)
    JSR BELL
    JMP askSlotNumber

; check if a DAN][ controller is installed in given slot
checkDanSlot:
    LDA SLOTNUM
    ORA #$C0            ; calculate slot address
    STA bufhi           ; prepare pointer to slot ROM
    LDA #$00
    STA buflo
    LDY #DAN_ID_LEN-1   ; last byte to be checked
checkLoop:
    LDA DAN_ID,Y        ; load signature byte
    CMP (buflo),Y       ; compare with slot ROM
    BEQ :+
    RTS                 ; card not detected (return with Z=1)
:   DEY                 ; next byte
    BPL checkLoop       ; until all bytes were checked
    LDA #$00            ; ok, card found (return with Z=0)
    RTS

; ID to check presence of a DAN][ controller (actually a ProDOS interface header)
DAN_ID_LEN = 8
DAN_ID:
    .BYTE $E0, $20, $A0, $00, $E0, $03, $A2, $3C

; string resources
MSGS:
MSG_ABORTED:
        .BYTE 13+128,13+128
        ASCHI "FIRMWARE UPDATE ABORTED!"
        .BYTE 13+128,0
MSG_ASK_SLOT:
        .BYTE 13+128
        ASCHI "CONTROLLER SLOT: #"
        .BYTE 0
MSG_NO_DANII:
        ASCHI "SORRY, NO DANII CONTROLLER IN #"
        .BYTE 0
MSG_INVALID_SLOT:
        ASCHI "INVALID SLOT NUMBER! "
.IFDEF APPLE3
        ASCHI "USE 1-4."
.ELSE
        ASCHI "USE 1-7."
.ENDIF
        .BYTE 13+128,0
MSG_PRESS_START:
        .BYTE 13+128
        ASCHI "PRESS"
        .BYTE 13+128
        ASCHI "      "
.IFDEF APPLE3
        ASCINV "<RESET>"         ; just the RESET button for Apple III
.ELSE
        ASCINV "<CTRL-RESET>"    ; need CTRL-RESET for Apple II
.ENDIF
        ASCHI " TO START UPDATE"
        .BYTE 13+128
        ASCHI "      OR ANY OTHER KEY TO ABORT."
        .BYTE 13+128,0
MSG_WELCOME:
        ASCINV "            DANII CONTROLLER           "
        .BYTE 13+128
  .IFDEF ATMEGA328P
        ASCINV "               ATMEGA328P              "
  .ENDIF
  .IFDEF ATMEGA644P
        ASCINV "               ATMEGA644P              "
  .ENDIF
        .BYTE 13+128
        ASCINV "         FIRMWARE UPDATER "
        .BYTE FW_MAJOR+$30,'.',FW_MINOR+$30,'.',FW_MAINT+$30
        ASCINV "        "
        .BYTE 13+128,13+128
        ASCHI "PRESS ESC TO ABORT..."
        .BYTE 13+128,0


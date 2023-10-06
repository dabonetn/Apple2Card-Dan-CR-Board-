; DAN][ Arduino firmware update utility: STK500 protocol driver.
; Copyright 2023 Thorsten C. Brehm

;.DEFINE FLASH_PROG_DISABLED    ; switch to disable flash programming (for testing only)

.setcpu "6502"

; include ROM routines for Apple II or III
.include "AppleROM.inc"

; export some labels
.export FW_START
.export FW_END
.export FW_SIZE_BYTES
.export FW_SIZE_WORDS
.export SLOTNUM
.export MSG_ADDR
.export print
.export DAN2_FWUPDATE
.import CLEAR_WARMSTART

.IFDEF ATMEGA328P
  ; page size is given in words (1word = 2bytes)
  PAGE_SIZE =   64
  ; page where the bootloader begins (not to be touched)
  END_PAGE  =  $3f
  DAN_CARD  =  3 ; type 3 reported by bootloader for ATMEGA328P
.ELSE
.IFDEF ATMEGA644P
  ; page size is given in words (1word = 2bytes)
  PAGE_SIZE =  128
  ; page where the bootloader begins (not to be touched)
  END_PAGE  =  $7e
  DAN_CARD  =  4 ; type 4 reported by bootloader for ATMEGA644P
.ELSE
 .ERROR No valid platform defined!
.ENDIF
.ENDIF

; temp variables
danx    = $43  ; X register value for accessing the DAN controller
buflo   = $44  ; low address of buffer
bufhi   = $45  ; hi address of buffer
adrlo   = $46  ; lower flash word address
adrhi   = $47  ; upper flash word address

; variables
SLOTNUM  = $0310
RETRIES  = $0311

; STK500 commands
STK_OK              = $10
STK_INSYNC          = $14  ; ' '
STK_CRC_EOP         = $20  ; 'SPACE'
STK_GET_SYNC        = $30  ; '0'
STK_GET_PARAMETER   = $41  ; 'A'
STK_LEAVE_PROGMODE  = $51  ; 'Q'
STK_LOAD_ADDRESS    = $55  ; 'U'
STK_PROG_PAGE       = $64  ; 'd'
STK_READ_PAGE       = $74  ;
STK_READ_SIGN       = $75  ; 'u'
STK_SW_MAJOR        = $81  ; ' '
STK_SW_MINOR        = $82  ; ' '

STK_DANII_TYPE      = $D2  ; custom STK parameter ID to obtain type of DANII board type (ATMEGA328P=3, ATMEGA644P=4)

.MACRO   PRINT STRVAR
    LDA #<STRVAR      ; use full 16bit address, since string resource has
    STA MSG_ADDR      ; outgrown 256 bytes...
    LDA #>STRVAR
    STA MSG_ADDR+1
    JSR print
.ENDMACRO

  ; code is relocatable
.segment	"CODE"

setupBuffer:        ; setup local buffer pointer and Arduino flash word address
    lda  #<FW_START ; load lower address of firmware data buffer
    sta  buflo
    lda  #>FW_START ; load higher address of firmware data buffer
    sta  bufhi
    lda  #$00
    sta  adrhi      ; clear Arduino flash word address
    sta  adrlo
    rts

DAN2_FWUPDATE:
    PRINT(MSG_SYNC)  ; "SYNC"

    lda  SLOTNUM     ; selected slot number
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax
    stx  danx

    lda  #$FA        ; set register A control mode to 2
    sta  $BFFB,x     ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

    jsr  doSTKsync   ; do STK500 synchronisation

    PRINT(MSG_OK)    ; "OK!"
    PRINT(MSG_BOOTL) ; "BOOTLOADER"

    ; show bootloader version (major.minor)
    lda  #STK_SW_MAJOR
    jsr  doSTKgetParam
    jsr  PRHEX2

    lda  #'.'+128
    jsr  COUT

    lda  #STK_SW_MINOR
    jsr  doSTKgetParam
    jsr  PRHEX2
    lda  #13+128
    jsr  COUT

    PRINT(MSG_HW_TYPE) ; "HARDWARE TYPE:"

    ; show card type: 3=ATMEGA328P or 4=ATMEGA644P?
    lda #STK_DANII_TYPE
    jsr  doSTKgetParam
    pha
    jsr  PRHEX2
    lda  #13+128
    jsr  COUT
    pla

    ; check if hardware type matches the type of this firmware
    cmp #DAN_CARD
    beq hw_ok

    ; dang. The card reports a mismatching type. A different firmware type is required.
    PRINT(MSG_HW_MISMATCH)
    jmp stop

hw_ok:
    ; install monitor as warmstart handler for debugging
;    lda  #>MONITOR
;    ldx  #<MONITOR
;    jsr setWarmStartAX

.IFNDEF FLASH_PROG_DISABLED
    ; flash programming
    PRINT(MSG_FLASH)   ; "FLASHING"
    jsr  setupBuffer
    jsr  program
    PRINT(MSG_OK)      ; "OK!"
.ENDIF

    ; verify flash content
    PRINT(MSG_VERIFY)  ; "VERIFYING"
    jsr  setupBuffer
    jsr  verify
    PRINT(MSG_OK)      ; "OK!"

    ; leave programming mode. Not strictly necessary
    lda  #STK_LEAVE_PROGMODE
    jsr  writebyte
    lda  #STK_CRC_EOP
    jsr  writebyte

    PRINT(MSG_COMPLETE); "UPDATE COMPLETE"

stop:
    jsr  CLEAR_WARMSTART
    jmp  stop

verify:
    jsr  doSTKloadAddress  ; load address
    lda  adrhi
    cmp  #$ff              ; set when doSTKloadAddress reached the end
    beq  _verify_done
    jsr  doSTKverifyBlock  ; read and verify data
    clc                    ; increase word address
    lda  adrlo
    adc  #PAGE_SIZE        ; 64words = 128 bytes (328P); 128W=256B (644P)
    sta  adrlo
    bcc  verify
    inc  adrhi
    lda  adrhi
    jsr  PRHEX2
    dec  CH
    dec  CH
.IFDEF APPLE3
    dec  CH                ; APPLE III ROM assumes 2 bytes per character
    dec  CH
.ENDIF
    lda  adrhi
    cmp  #END_PAGE         ; never consider addresses matching or beyond END_PAGE (where the protected bootloader is)
    bmi  verify
_verify_done:
    rts

program:
    jsr  doSTKloadAddress  ; load address
    lda  adrhi
    cmp  #$ff              ; set when doSTKloadAddress reached the end
    beq  _program_done
    jsr  doSTKwriteBlock   ; program data to flash
    clc                    ; increase word address
    lda  adrlo
    adc  #PAGE_SIZE        ; 64words = 128 bytes (328P) 128W=256B (644P)
    sta  adrlo
    bcc  program
    inc  adrhi
    lda  adrhi
    jsr  PRHEX2
    dec  CH
    dec  CH
.IFDEF APPLE3
    dec  CH                ; APPLE III ROM assumes 2 bytes per character
    dec  CH
.ENDIF
    lda  adrhi
    cmp  #END_PAGE         ; never consider addresses matching or beyond END_PAGE (where the protected bootloader is)
    bmi  program
_program_done:
    rts

error:
    pha
    PRINT(MSG_ERROR)
    pla
    jsr  PRHEX2
badprog:
    jmp  badprog

doSTKwriteBlock:
    lda  #STK_PROG_PAGE
    jsr  doSTKrwCmd

    jsr  writepage

    lda  #STK_CRC_EOP
    jsr  writebyte

    jmp  doSTKInsyncOk

doSTKrwCmd:
    jsr  writebyte         ; send command byte
    lda  #>(PAGE_SIZE * 2) ; convert words to bytes
    jsr  writebyte         ; send length (128 byte, or 256 bytes)
    lda  #<(PAGE_SIZE * 2)
    jsr  writebyte
    lda  #'F'              ; send 'F'lash target
    jmp  writebyte

doSTKverifyBlock:
    lda  #STK_READ_PAGE
    jsr  doSTKrwCmd

    lda  #STK_CRC_EOP
    jsr  writebyte

    jsr  readbyte
    cmp  #STK_INSYNC
    bne  error

    jsr  verifypage

    jsr  readbyte
    cmp  #STK_OK
    bne  error

    rts

doSTKInsyncOk:
    jsr  readbyte
    cmp  #STK_INSYNC
    bne  error
    jsr  readbyte
    cmp  #STK_OK
    bne  error
    rts

doSTKloadAddress:
    ; first, compare the AVR address we want with the maximum (in words)
    ; and set adrhi to 0xff, and exit, if we reached the end
    lda  adrhi
    cmp  #>FW_SIZE_WORDS
    bne  _no_overflow
    lda  adrlo
    cmp  #<FW_SIZE_WORDS
    bne  _no_overflow
    lda  #$ff
    sta  adrhi
    rts
_no_overflow:
    lda  #STK_LOAD_ADDRESS
    jsr  writebyte
    lda  adrlo
    jsr  writebyte
    lda  adrhi
    jsr  writebyte
    lda  #STK_CRC_EOP
    jsr  writebyte
    jmp  doSTKInsyncOk

doSTKgetParam:
    pha
    lda  #STK_GET_PARAMETER
    jsr  writebyte
    pla
    jsr  writebyte
    lda  #STK_CRC_EOP
    jsr  writebyte

    jsr  readbyte
    cmp  #STK_INSYNC
    bne  error2

    jsr  readbyte
    pha

    jsr  readbyte
    cmp  #STK_OK
    bne  error2

    pla
    rts
error2:
    jmp error

doSTKsync:
    lda  #80          ; give up after some attempts
    sta  RETRIES      ; retry counter
syncretry:
    lda  RETRIES      ; any attempts left?
    beq  nosync       ; no? Abort...

    dec  RETRIES
    lda  #'.'+$80     ; show "."
    jsr  COUT

    lda  #STK_GET_SYNC; send "GET_SYNC"
    jsr  writebyte
    lda  #STK_CRC_EOP ; send "CRC_EOP"
    jsr  writebyte
    jsr  checkinput   ; any reply available?
    beq  syncretry    ; no? try sync again...

    jsr  readbyte     ; read reply
    cmp  #STK_INSYNC
    bne  syncretry

    jsr  checkinput   ; any reply available?
    beq  syncretry    ; no? try sync again...

    jsr  readbyte     ; read the byte
    cmp  #STK_OK
    bne  syncretry

    rts

nosync:
    PRINT(MSG_NOSYNC)
    JSR BELL
wait:
.IFDEF APPLE3
     jsr RDKEY       ; need the RDKEY for Apple 3 since the cursor is otherwise not visible
.ENDIF
     jmp wait

delay:
    ldy  #$10
dly:
    dey
    bne  dly
    rts

writebyte:
    ldx  danx
    sta  $BFF8,x     ; push it to the Arduino
writebyte2:
    lda  $BFFA,x     ; get port C
    bpl  writebyte2  ; wait until its received (OBFA is high)
    rts

writepage:           ; write a flash page of 128, or 256 bytes
    ldy  #$00
writepage2:
    lda  (buflo),y   ; write a byte to the Arduino
    jsr  writebyte
    iny
.IF PAGE_SIZE < 128
    bpl  writepage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
.ELSE
.IF PAGE_SIZE = 128
    bne  writepage2
    inc  bufhi
.ELSE
    .ERROR Unsupported page size!
.ENDIF
.ENDIF
    rts

checkinput:
    jsr  delay
    ldx  danx
    lda  $BFFA,x     ; wait until there is a byte available
    and  #$20
    rts

readbyte:
    ldx  danx
readbyte2:
    lda  $BFFA,x     ; wait until there is a byte available
    and  #$20
    beq  readbyte2
    lda  $BFF8,x     ; get the byte
    rts

readpage:
    ldy  #$00
readpage2:
    jsr  readbyte
    sta  (buflo),y
    iny
.IF PAGE_SIZE < 128
    bpl  readpage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
.ELSE
.IF PAGE_SIZE = 128
    bne  readpage2
    inc  bufhi
.ELSE
    .ERROR Unsupported page size!
.ENDIF
.ENDIF
    rts

verifypage:
    ldy #$00
verifypage2:
    jsr  readbyte
    cmp  (buflo),y
    bne  verifyerr
    iny
.IF PAGE_SIZE < 128
    bpl  verifypage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
.ELSE
.IF PAGE_SIZE = 128
    bne  verifypage2
    inc  bufhi
.ELSE
    .ERROR Unsupported page size!
.ENDIF
.ENDIF
    rts
verifyerr:
    pha              ; error code
;    lda (buflo),y
;    sta USR_DATA    ; store data byte of verify error
    lda #13+128
    jsr COUT
    pla
    jmp error

PRHEX2:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr  PRHEX
    pla
    jmp  PRHEX

; print string
print:
    ldx #$00
    MSG_ADDR=*+1
:   lda MSGS,x
    beq ret
    jsr COUT
    inx
    bne :-
ret:rts

MSGS:
MSG_SYNC:
        ASCHI " "
        .BYTE  13+128
         ASCHI "STARTING FIRMWARE UPDATE..."
        .BYTE  13+128,13+128
         ASCHI "  WAITING FOR SYNC"
        .BYTE  0
MSG_OK:  ASCHI  "OK! "
        .BYTE 0
MSG_ERROR:
         ASCINV "ERROR! "
        .BYTE  0
MSG_BOOTL:
        .BYTE 13+128
        ASCHI "  BOOTLOADER: V"
        .BYTE 0
MSG_HW_TYPE:
        .BYTE 13+128
        ASCHI "  HARDWARE TYPE (3=328P, 4=644P): "
        .BYTE 0
MSG_HW_MISMATCH:
        .BYTE 13+128
        ASCHI "  HARDWARE MISMATCH!"
        .BYTE 13+128
        ASCHI "  FIRMWARE DOES NOT MATCH THIS CARD."
        .BYTE 0
MSG_VERIFY:
        .BYTE 13+128
        ASCHI "  VERIFYING "
        .BYTE 0
MSG_FLASH:
        .BYTE 13+128
        ASCHI "  FLASHING "
        .BYTE 0
MSG_NOSYNC:
        .BYTE 13+128
        ASCHI "  NO SYNC. TRY AGAIN."
        .BYTE 13+128,0
MSG_COMPLETE:
        .BYTE 13+128,13+128
        ASCINV "UPDATE COMPLETE! RESTART TO CONTINUE."
        .BYTE 13+128,0

; include the actual firmware binary
FW_START:
  .IFDEF ATMEGA328P
        .incbin   "bin-328p/fwimage.bin"
  .ENDIF
  .IFDEF ATMEGA644P
        .incbin   "bin-644p/fwimage.bin"
  .ENDIF
FW_END:

; calculate firmware size in bytes and words
FW_SIZE_BYTES = FW_END-FW_START
FW_SIZE_WORDS = FW_SIZE_BYTES/2

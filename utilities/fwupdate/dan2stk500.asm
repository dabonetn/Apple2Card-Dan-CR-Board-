; DAN][ Arduino firmware update utility: STK500 protocol driver.
; Copyright 2023 Thorsten C. Brehm

.setcpu		"6502"


.IFDEF ATMEGA328P
  PAGE_SIZE =   64
  END_PAGE  =  $3f
.ELSE
.IFDEF ATMEGA644P
  PAGE_SIZE =  128
  END_PAGE  =  $7e
.ELSE
 .ERROR No valid platform defined!
.ENDIF
.ENDIF

; export the interface functions
.export setFwUpdateHook
.export clearWarmStartVec

; temp variables
danx    = $43  ; X register value for accessing the DAN controller
buflo   = $44  ; low address of buffer
bufhi   = $45  ; hi address of buffer
adrlo   = $46  ; lower flash word address
adrhi   = $47  ; upper flash word address

; monitor subroutines
PRHEX    = $FDE3
PRBYTE   = $FDDA
RDKEY    = $FD0C
COUT     = $FDED
MONITOR  = $FF69

; Apple II monitor registers
CH       = $24   ; horizontal cursor position
CV       = $25
BASL     = $28
BASH     = $29

SOFTEV   = $03f2 ; vector for warm start
PWREDUP  = $03f4 ; this must = EOR #$A5 of SOFTEV+1

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

; generate Apple-ASCII string (with MSB set)
.MACRO   ASCHI STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) | $80
.ENDREP
.ENDMACRO

; generated string with inverted characters
.MACRO   ASCINV STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) & $3F
.ENDREP
.ENDMACRO

.MACRO   PRINT STRVAR
    ldx #(STRVAR-MSGS)
    jsr print
.ENDMACRO

  ; code is relocatable
.segment	"CODE"

clearWarmStartVec:  ; clear the warm start hook
    lda #$00
    sta PWREDUP
    sta SOFTEV
    sta SOFTEV+1
    rts

setFwUpdateHook:    ; install warm start hook
    lda CV          ; remember cursor position
    sta $0830
    lda BASL
    sta $0831
    lda BASH
    sta $0832

    ldx #<dan2fwupdate ; address of warm start hook
    lda #>dan2fwupdate
setWarmStartAX:     ; address in A and X
    stx SOFTEV      ; set lower address of hook
    sta SOFTEV+1    ; set upper address of hook
    eor #$A5        ; warm start magic byte
    sta PWREDUP     ; must match (SOFTEV+1)^$A5 to trigger warm start
    rts

setupBuffer:        ; setup local buffer pointer and Arduino flash word address
    lda  #<FW_START ; load lower address of firmware data buffer
    sta  buflo
    lda  #>FW_START ; load higher address of firmware data buffer
    sta  bufhi
    lda  #$00
    sta  adrhi      ; clear Arduino flash word address
    sta  adrlo
    rts

dan2fwupdate:
    lda $0830        ; restore cursor position after warm start
    sta CV
    lda $0831
    sta BASL
    lda $0832
    sta BASH

    PRINT(MSG_SYNC)  ; "SYNC"

    lda  $0820       ; slot number passed in $820
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

    ; install monitor as warmstart handler for debugging
    lda  #>MONITOR
    ldx  #<MONITOR
    jsr setWarmStartAX

    ; flash programming
    PRINT(MSG_FLASH)   ; "FLASHING"
    jsr  setupBuffer
    jsr  program
    PRINT(MSG_OK)      ; "OK!"

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
    jsr  clearWarmStartVec

stop:
    jmp  stop

verify:
    jsr  doSTKloadAddress  ; load address
    lda  adrhi
    cmp  #$ff              ; set when doSTKloadAddress reached the end
    beq  _verify_done
    jsr  doSTKverifyBlock  ; read and verify data
    clc                    ; increase word address
    lda  adrlo
    adc  #PAGE_SIZE        ; 64words = 128 bytes (328P); 128=w (644P)
    sta  adrlo
    bcc  verify
    inc  adrhi
    lda  adrhi
    jsr  PRHEX2
    dec  CH
    dec  CH
    jmp  verify
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
    jmp  program
_program_done:
    rts

error:
    pha
    ldx  #MSG_ERROR-MSGS
    jsr  print
    pla
    jsr  PRHEX2
    jmp  stop

doSTKwriteBlock:
    lda  #STK_PROG_PAGE
    jsr  doSTKrwCmd

    jsr  writepage

    lda  #STK_CRC_EOP
    jsr  writebyte

    jmp  doSTKInsyncOk

doSTKrwCmd:
    jsr  writebyte   ; send command byte
    lda  #>(PAGE_SIZE * 2)
    jsr  writebyte   ; send length (128 byte, or 256 bytes)
    lda  #<(PAGE_SIZE * 2)
    jsr  writebyte
    lda  #'F'        ; send 'F'lash target
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
    cmp  #>AVR_SIZE
    bne  _no_overflow
    lda  adrlo
    cmp  #<AVR_SIZE
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
    lda  #'.'+$80
    jsr  COUT

    lda  #STK_GET_SYNC
    jsr  writebyte
    lda  #STK_CRC_EOP
    jsr  writebyte
    jsr  checkinput   ; any reply available?
    beq  doSTKsync    ; no? try sync again...

    jsr  readbyte     ; read reply
    cmp  #STK_INSYNC
    bne  doSTKsync

    jsr  checkinput   ; any reply available?
    beq  doSTKsync    ; no? try sync again...

    jsr  readbyte     ; read the byte
    cmp  #STK_OK
    bne  doSTKsync

    rts

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
#if PAGE_SIZE < 128
    bpl  writepage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
#else
    bne  writepage2
    inc  bufhi
#endif
    rts

checkinput:
    jsr  delay
    ldx  danx
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20
    rts

readbyte:
    ldx  danx
readbyte2:
    lda  $BFFA,x     ; wait until there's a byte available
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
#if PAGE_SIZE < 128
    bpl  readpage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
#else
    bne  readpage2
    inc  bufhi
#endif
    rts

verifypage:
    ldy #$00
verifypage2:
    jsr  readbyte
    cmp  (buflo),y
    bne  verifyerr
    iny
#if PAGE_SIZE < 128
    bpl  verifypage2
    clc              ; now increase buffer pointer by 128 bytes
    lda  buflo
    adc  #(PAGE_SIZE * 2)
    sta  buflo
    lda  bufhi
    adc  #$00        ; add carry
    sta  bufhi
#else
    bne  verifypage2
    inc  bufhi
#endif
    rts
verifyerr:
    sta $0800
    lda (buflo),y
    sta $0801
    lda #13+128
    jsr COUT
    lda $0800
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

print:
    lda MSGS,x
    beq ret
    jsr COUT
    inx
    bne print
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
MSG_VERIFY:
        .BYTE 13+128
        ASCHI "  VERIFYING "
        .BYTE 0
MSG_FLASH:
        .BYTE 13+128
        ASCHI "  FLASHING "
        .BYTE 0
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

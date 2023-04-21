; DAN][ interface to configure the FTP IP address
; by Thorsten C. Brehm, based on firmware by DL Marks

.setcpu		"6502"

; export the interface function
.export dan2if_do

;temp variables because 6502 only has 3 registers
uppage = $FD

;ProDOS defines
command = $42  ; ProDOS command
unit    = $43  ; 7=drive 6-4=slot 3-0=not used
buflo   = $44  ; low address of buffer
bufhi   = $45  ; hi address of buffer
blklo   = $46  ; low block
blkhi   = $47  ; hi block

ioerr   = $27  ; I/O error code
nodev   = $28  ; no device connected
wperr   = $2B  ; write protect error

; DAN][ commands
GETSTATUS    =  0
READBLOCK    =  1
WRITEBLOCK   =  2
FORMATBLOCK  =  3
SETVOLUME    =  4  ; set EEPROM volume configuration, single byte response
SETVOLUME512 =  7  ; set EEPROM volume configuration, 512 byte response
TMPVOL512    =  6  ; set temporary volume configuration, 512 byte response
TMPVOL1      =  8  ; set temporary volume configuration, single byte response
GETVOLCFG    =  5  ; get EEPROM volume configuration
GETVOLTMP    =  9  ; get temporary volume configuration
SAFEREAD     = 10  ; failsafe read. Reads block from volume. Reads from bootprogram if volume was missing.
SETIPCFG     = $20 ; set FTP/IP configuration
GETIPCFG     = $21 ; get FTP/IP configuration
ILLEGALCMD   = $FF ; An illegal command, always returning error $27.
MAGICDAN     = $AC ; magic byte for all commands

  ; code is relocatable
.segment	"CODE"

dan2if_do:
    ; save registers
    pha
    txa
    pha
    tya
    pha

    ; prepare command registers
    lda #$08
    sta bufhi
    lda #$00
    sta buflo
    sta blklo
    sta blkhi

    lda  $0821       ; command passed in $821
    sta  command
    ldx  $0820       ; slot number passed in $820
    txa
    asl
    asl
    asl
    asl
    sta  unit

    ldy  #$00
    sty  $0820
    sty  $0821
    jsr  dan_do
    sta  $0820       ; return code
;    jmp  $ff69      ; debug

    ; restore registers
    pla
    tay
    pla
    tax
    pla
    rts

dan_do:              ; slot number passed in X
    txa
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax

    lda  #$FA        ; set register A control mode to 2
    sta  $BFFB,x     ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

    ldy	 #$ff        ; lets send the command bytes directly to the Arduino
    lda  #MAGICDAN   ; send this byte first as a magic byte
    bne  comsend
combyte:
    lda  command,y   ; get byte
comsend:
    sta  $BFF8,x     ; push it to the Arduino
combyte2:
    lda  $BFFA,x     ; get port C
    bpl  combyte2    ; wait until its received (OBFA is high)
    iny
    cpy  #$06
    bne  combyte     ; send next byte
waitresult:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20
    beq  waitresult
    lda  $BFF8,x     ; get the byte
    beq  noerror     ; yay, no errors!  can process the result
    sec              ; pass the error back to ProDOS
    rts
noerror:
    sta  uppage      ; keep track if we are in upper page (store 0 in uppage)
    tay              ; (store 0 in y)
notstatus:
    lda  command
    cmp  #SETIPCFG
    bne  readbytes    ; not a write command
writebytes:
    lda  (buflo),y    ; write a byte to the Arduino
    sta  $BFF8,x
waitwrite:
    lda  $BFFA,x      ; wait until its received
    bpl  waitwrite
    iny
    bne  writebytes
    ldy  uppage
    bne  exit512     ; already wrote upper page
    inc  bufhi
    inc  uppage
    bne  writebytes
exit512:
    dec  bufhi       ; quit with no error
quitok:
    ldx  unit
    lda  #$00
    clc
    rts
readbytes:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20
    beq  readbytes
    lda  $BFF8,x     ; get the byte
    sta  (buflo),y   ; store in the buffer
    iny
    bne  readbytes   ; get next byte to 256 bytes
    ldy  uppage
    bne  exit512     ; already read upper page
    inc  bufhi
    inc  uppage
    bne  readbytes


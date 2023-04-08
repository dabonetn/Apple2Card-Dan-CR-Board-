; DAN][ Boot ROM
; by DL Marks, TC Brehm

;temp variables because 6502 only has 3 registers
uppage = $FD

;for relocatable code, address to jump to instead of JSR absolute + RTS
knownRtsMonitor = $FF58
sloop           = $faba
waitloop        = $fca8

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

; Keys
ESCAPE  = 27+128
RETURN  = 13+128
SPACE   = 32+128

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
ILLEGALCMD   = $FF ; An illegal command, always returning error $27.
MAGICDAN     = $AC ; magic byte for all commands

   .org  $C700
  ; code is relocatable
  ; but set to $c700 for
  ; readability

; ID bytes for booting and drive detection
idbytes:
    cpx  #$20        ; ID bytes for ProDOS and the
    ldy  #$00        ; Apple Autostart ROM
    cpx  #$03        ;
    ldx  #$3C        ; this one for older II's
    bne  boot
jumpbank:
    lda  #$01        ; jump to other bank
anybank:
    sta  $bffb,x     ; this is called to switch between rom banks
    dey              ; Y==1?
    beq  gosloop     ; Y==1: sloop
    dey              ; Y==2?
    bne  pushadr     ; Y>2: pushadr/load
                     ; Y now 0 at this point

boot:                ; boot it
                     ; Y is already 0
    sty  buflo       ; zero out block numbers and buffer address
    lda  #SAFEREAD
    sta  command     ; command: 10=failsafe readblock (read normal block. if volume is missing, read from bootprogram instead)

    jsr  knownRtsMonitor; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
    sta  bufhi       ; address of beginning of rom

    asl  a
    asl  a
    asl  a
    asl  a
    sta  unit        ; store unit number so Arduino knows what to load
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax

    lda  #$FA        ; set register A control mode to 2
    sta  $BFFB,x     ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

    ldy  #<msg
writemsg:
    lda  (buflo),y
    beq  waitkey
    sta	 $6D0-<msg,y
    iny
    bne  writemsg

gosloop:
    jmp  sloop

gobank2:
    sta  $c010       ; clear key press
    tay
    bmi jumpbank

waitkey:             ; y is approximately $ff here on initial call
    lda  #$40        ; wait a little
    jsr  waitloop    ; do the wait
    lda  $c000       ; do we have a key
    bmi  gobank2     ; keypress is handled by second page
    dey              ; calculate timeout
    bne  waitkey

pushadr:
    lda  #$08        ; push return address on stack
    sta  bufhi
    pha
    lda  #$00
    pha
    sta  blklo       ; always load block 0
    sta  blkhi
    ldx  #$01
    sta  (buflo,X)   ; write "BRK" to $801, so if loading fails (volume does not exist, it breaks to monitor immediately)

start:
    lda  #$60
    sta  uppage
    jsr  uppage      ; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
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
    lda  command
    bne  notstatus   ; not a status command
    
    ldx  #$FF        ; report $FFFF blocks 
    dey              ; y = 0 to y = $ff
    clc
    rts
    
notstatus:
    cmp  #WRITEBLOCK
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

; assume read command
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
    
;macro for string with high-bit set
.macro aschi str
.repeat .strlen (str), c
.byte .strat (str, c) | $80
.endrep
.endmacro

msg:   aschi   "DAN II: PRESS RETURN"
endmsg:

; These bytes need to be at the top of the 256 byte firmware as ProDOS
; uses these to find the entry point and drive capabilities

.repeat	252+idbytes-endmsg
.byte 0
.endrepeat

.byte   $00,$00  ;0000 blocks = check status
.byte   $B7      ;status,read,write,no format,2 volumes,removable
.byte  <start    ;low byte of entry

; this starts at $c700, page 2

page2:
; ID bytes for booting and drive detection
    cpx  #$20    ; ID bytes for ProDOS and the
    ldy  #$00    ; Apple Autostart ROM
    cpx  #$03    ;
    ldx  #$3C    ; this one for older II's
    bne  badpage ; why are we booting to this page?
jumpbank2:
    lda  #$00    ; jump back to the original bank
    sta  $bffb,x ; this is called to switch between rom banks
badpage:
    tya
    ldy  #$02
    cpx  #$3C
    beq  jumpbank2  ; badpage detected? switch back to first bank with Y=2 (boot)

keypressed:         ; enty from bank 0 when key was pressed
    pha             ; save key

waitarduino:
    lda  $BFF8,x    ; clear possible pending/spurious input byte

    lda #SPACE      ; clear "PRESS RETURN" message
    ldy #30
clrline:
    dey
    sta $6D0+6,y
    bne clrline

    lda  #MAGICDAN
    sta  $BFF8,x    ; send command sync byte
dly:
    dey
    bne dly         ; delay
    lda  $BFFA,x    ; wait until Arduino is ready
    and  #$A0       ; check OBFA/IBFA
    cmp  #$80       ; OBFA==1, IBFA==0?
    bne  waitarduino

    lda  #ILLEGALCMD; command $FF: always returning an error ($27)
    sta  $BFF8,x    ; send command to Arduino
dly2:
    dey
    bne  dly2       ; wait a bit
    lda  $BFF8,x    ; read input byte
    cmp #$27
    bne waitarduino ; keep syncing, until reponse is as expected

    pla             ; restore key
    iny             ; Y=1
    cmp  #ESCAPE    ; see if ESCAPE key is pressed
    beq  jumpbank2  ; ESCAPE key => Y=1: sloop
    tay             ; Y>2
noesc:
    cmp  #'0'+128
    bmi  notanumber
    cmp  #'9'+128+1
    bpl  notanumber
    and  #$0f
    sta  blklo
    lda  #TMPVOL1   ; temporary selection volume 1
    bne  doconfig   ; unconditional branch
notanumber:
    cmp  #'X'+128   ; see if X is pressed (SPACE now boots the currently selected volume...)
    beq  configmenu ; go to old ROM configuration menu
    cmp  #RETURN    ; see if RETURN is pressed
trampoline:
    bne  jumpbank2
    sta  command    ; load new boot menu
    beq  jumpbank2  ; unconditional branch

configmenu:
    ldy	 #<card1msg
writecard1msg:
    lda	 (buflo),y
    beq  getcard1key
    sta	 $750-<card1msg,y
    iny
    bne  writecard1msg
    ; should never fall through here from previous instruction

getcard1key:
    lda  $c000
    bpl  getcard1key
    sta  $c010
    cmp  #'!'+128
    bne  notex1
    tay
    lda  #$ff
    bne  storevol1
notex1:
    cmp  #'0'+128
    bcc  getcard1key
    cmp  #'9'+128+1
    bcs  getcard1key
    tay
    and  #$0f
storevol1:
    sty  $750+20     ; show card1 selection
    sta  blklo       ; write card1 selection to command buffer

    ldy	 #<card2msg
writecard2msg:
    lda	 (buflo),y
    beq  getcard2key
    sta	 $7D0-<card2msg,y
    iny
    bne  writecard2msg
    ; should never fall through here from previous instruction

getcard2key:
    lda  $c000
    bpl  getcard2key
    sta  $c010
    cmp  #'0'+128
    bcc  getcard2key
    cmp  #'9'+128+1
    bcs  getcard2key
    sta  $7D0+20     ; show card2 selection
    and  #$0f
    sta  blkhi       ; write card2 selection to command buffer

    lda  #SETVOLUME  ; configure volumes command
doconfig:
    sta  command

    ldy	 #$ff        ; lets send the command bytes directly to the Arduino
    lda  #MAGICDAN   ; send this byte first as a magic byte
    bne  pcomsend
pcombyte:
    lda  command,y   ; get byte
pcomsend:
    sta  $BFF8,x     ; push it to the Arduino
pcombyte2:
    lda  $BFFA,x     ; get port C
    bpl  pcombyte2   ; wait until its received (OBFA is high)
    iny
    cpy  #$06
    bne  pcombyte    ; send next byte
                     ; Y is 6, carry is set
pwaitresult:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20  
    beq  pwaitresult
    
    lda  $BFF8,x     ; get the byte
    lda  #SAFEREAD   ; failsafe read block
    sta  command
    bne  trampoline  ; boot volume (with Y>2)

card1msg:   aschi   "CARD 1 (0-9,!):"
end1msg:
.byte    0
card2msg:   aschi   "CARD 2 (0-9):"
end2msg:
.byte    0

.repeat	255+page2-end2msg
.byte 0
.endrepeat


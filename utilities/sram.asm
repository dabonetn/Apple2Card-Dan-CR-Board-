; Simple SRAM loader utility for debugging.
; by TC Brehm, based on flash loader by DL Marks.
;
; - Use an 32K SRAM (62256) instead of the (E)EPROM for debugging.
; - Set JP6/PROGRAM jumper. Jumper can remain set for debugging.
; - Of course, power-up tests won't work. You have to load the SRAM first,
;   then press Ctrl-RESET.
; - Just for quick testing of experimental ROMs, without the need to mess
;   with jumpers.

;  zero page locations used
  movelo  = $f8
  movehi  = $f9
  romlo   = $fa  ; rom hi
  romhi   = $fb
  ioffset = $fc  ; io space offset
  slotnum = $fd  ; slot number
  loclo   = $fe  ; location lo
  lochi   = $ff  ; location hi

  ; monitor subroutines
  home    = $fc58
  outch   = $fded
  rdkey   = $fd0c
  dowait  = $fca8

   .org  $2000
  ; origin for ProDOS system file

.macro aschi str
.repeat .strlen (str), c
.byte .strat (str, c) | $80
.endrep
.endmacro

start:
    jsr  home   ; clear the screen
    ldy  #<startmsg
    sty  loclo
    ldy  #>startmsg
    sty  lochi
    jsr  outmsg
getkey:
    jsr  rdkey     ; read a key
    cmp  #27+128
    bne  getkey1
    jmp  quitearly
getkey1:
    cmp  #'1'+128
    bcc  getkey
    cmp  #'7'+128+1
    bcs  getkey
    jsr  outch    ; output the digit
    and  #$07
    sta  slotnum

    pha                        ; store rom bank location
    ora  #$C0
    sta  romhi
    lda  #0
    sta  romlo
    pla                        ; store offset into io addresses
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88
    sta  ioffset

    ldy  #<loadingnow           ; let them know flashing is beginning
    sty  loclo
    ldy  #>loadingnow
    sty  lochi
    jsr  outmsg

    ldx  ioffset
    lda  #$FA                     ; set register A control mode to 2
    sta  $BFFB,x                  ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

startload:
    lda  #<romcontents            ; start copying at end of file
    sta  movelo
    lda  #>romcontents
    sta  movehi

    lda  #0                       ; start at this point in actual ROM
    sta  loclo
    sta  lochi

    lda  #$00                     ; select page 0
    sta  $BFFB,x
    ldy  #0
writepage0:
    lda  (movelo),y
    sta  (romlo),y
    iny
    bne  writepage0               ; 256byte page complete?

    inc  movehi                   ; data for second page
    lda  #$01                     ; select page 1
    sta  $BFFB,x
writepage1:
    lda  (movelo),y
    sta  (romlo),y
    iny
    bne  writepage1               ; 256byte page complete?

    lda  #$00                     ; back to page 0
    sta  $BFFB,x

complete:
    ldy  #<loadingcomplete
    sty  loclo
    ldy  #>loadingcomplete
    sty  lochi
    jsr  outmsg
waitenter:
    ldx  ioffset
    lda  #$fa
    sta  $bffb,x                 ; port B input, port C output in the control register
waitenter1:
    jsr  rdkey
    cmp  #13+128
    bne  waitenter1

    inc  $3f4      ; invalidate power up byte
    jsr  $bf00     ; quit to PRODOS
.byte  $65
.byte  <parmquit
.byte  >parmquit

quitearly:
    ldy  #<noload
    sty  loclo
    ldy  #>noload
    sty  lochi
    jsr  outmsg
    jmp  waitenter

parmquit:
.byte  4
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0

outmsg:
    ldy  #0
outmsg1:
    lda  (loclo),y
    beq  outend
    jsr  outch
    iny
    bne  outmsg1
outend:
    rts

startmsg:
    aschi   "SRAM LOADER UTILITY"
.byte    $8d
    aschi   "SHORT JP6/PROGRAM JUMPER"
.byte    $8d
    aschi   "ENTER SLOT NUMBER: (1-7,ESC QUIT) "
.byte    0

loadingnow:
.byte    $8d
    aschi   "LOADING NOW!"
.byte    $8d
.byte    0

loadingcomplete:
.byte    $8d
    aschi   "LOADING COMPLETE. PRESS ENTER."
.byte    $8d
.byte    0

noload:
.byte    $8d
    aschi   "DID NOT LOAD. PRESS ENTER."
.byte    $8d
.byte    0

romcontents:
                 ; rom contents get appended to this file


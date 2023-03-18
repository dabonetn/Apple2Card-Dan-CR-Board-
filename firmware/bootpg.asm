; Sample Bootloader Code
; by DL Marks
; not done yet

INSTRUC = $F0
LOWBT   = $F1
HIGHBT  = $F2
RTSBYT  = $F3
VOLDRIVE0 = $F5
VOLDRIVE1 = $F6
GVOLDRIVE0 = $F7
GVOLDRIVE1 = $F8
LENGTH = $F9
LASTVOL = $FA
VOL = $FB

BLKBUF = $1000

COMMAND = $42
UNIT    = $43
BUFLO   = $44
BUFHI   = $45
BLKLO   = $46
BLKHI   = $47

CH = $24
CV = $25

HOME =   $FC58
PRHEX =  $FDE3
PRBYTE = $FDDA
RDKEY =  $FD0C
COUT  =  $FDED
VTAB =   $FC22
SETVID = $FE93
SETKBD = $FE89

         .ORG $800

START:
         NOP
         LDA #$20
         STA INSTRUC
         LDA #$60        ; store RTS at $F3
         STA RTSBYT
         LDA UNIT        ; put unit in A register
         LSR A           ; shift to lower nibble
         LSR A
         LSR A
         LSR A
         AND #$07        ; just in case we booted from drive 2 ?
         ORA #$C0        ; make high nibble $C0
         STA HIGHBT      ; store high byte in memory location
         LDY #$00        ; store zero in low byte
         STY LOWBT
         DEY             ; make zero a $FF
         LDA (LOWBT),Y   ; get low byte of address
         STA LOWBT       ; place at low byte

         JSR SETVID      ; set to IN#0/PR#0 just in case
         JSR SETKBD
         JSR HOME        ; clear screen
         JSR GETVOL      ; get volume number
         LDA #(VOLSEL-MSGS) ; show title
         JSR DISPTITLE
         LDA #23
         JSR GOTOROW
         LDA #(A2FOREVER-MSGS) ; show title
         JSR DISPTITLE

READUNIT:
         LDA #0
         STA VOL         ; set drive number
         LDA #3
         STA CV          ; set screen row
UNITLOOP:
         JSR VTAB

         LDA VOL         ; set both drives to location
         STA VOLDRIVE0
         STA VOLDRIVE1
         JSR SETVOL

         LDA #0          ; start at column 0
         JSR DISPVOLUME  ; show item number and volume name

         LDA UNIT
         ORA #$80        ; check SD-card 2 (drive 1)
         STA UNIT        ; set high bit to get drive 1
         LDA #20         ; start at column 20
         JSR DISPVOLUME  ; show item number for volume
         LDA UNIT        ; clear high bit
         AND #$7F
         STA UNIT

         INC CV          ; go to next row
         INC VOL         ; go to next volume
         LDA VOL
         CMP #$10
         BCC UNITLOOP

VANITY:
         LDA #21         ; row 21
         JSR GOTOROW

DISPCUR: 
         JSR CARDMS0
         LDA #10
         STA CH
         LDA GVOLDRIVE0
         JSR DVHEX

         LDA #20
         STA CH
         JSR CARDMS1
         LDA #30
         STA CH 
         LDA GVOLDRIVE1
         JSR DVHEX

GETVL:
         LDA #10
         STA CH
         LDA GVOLDRIVE0
         JSR ASKVOL
         STA VOLDRIVE0
         JSR DVHEX
         LDA #30
         STA CH
         LDA GVOLDRIVE1
         JSR ASKVOL
         STA VOLDRIVE1
         JSR DVHEX

         JSR SETVOLW
         JMP REBOOT

ABORT:
         LDA GVOLDRIVE0
         STA VOLDRIVE0
         LDA GVOLDRIVE1
         STA VOLDRIVE1
         JSR SETVOL
         PLA
         PLA
         JMP REBOOT

ASKVOL:
         STA LASTVOL   ; remember previous volume selection
GETHEX:
         JSR RDKEY
         CMP #13+128   ; RETURN key
         BNE NORET
         LDA LASTVOL   ; load previous volume selection
         RTS
NORET:
         CMP #27+128   ; ESCAPE key
         BEQ ABORT
         CMP #'!'+128   ; is !
         BEQ SPCASE
         CMP #'a'+128
         BCC NOLOWER
         SEC
         SBC #$20 
NOLOWER:
         CMP #'A'+128
         BCC NOLET
         CMP #'F'+128+1
         BCC ISLET
NOLET:   CMP #'0'+128
         BCC GETHEX
         CMP #'9'+128+1
         BCS GETHEX
         AND #$0F
         RTS
ISLET:
         SEC
         SBC #7
         AND #$0F
         RTS
SPCASE:
         LDA #$FF
         RTS

DVHEX:   CMP #$FF
         BEQ DSPEC
         JMP PRHEX
DSPEC: 
         LDA #'!'+128
         JMP COUT

DISPVOLUME:              ; display volume number/name
         STA CH
         LDA VOL         ; print hex digit for row
         JSR PRHEX
         LDA #':'+128
         JSR COUT        ; print ":"
         INC CH          ; skip space
         JSR READB       ; read a block from drive 0
DISPNAME:
         LDX #0
         BCS NOHEADER    ; didn't read a sector
         LDA BLKBUF+5    ; if greater than $80 not a valid ASCII
         BMI NOHEADER
         LDA BLKBUF+4    ; look at volume directory header byte
         AND #$F0
         CMP #$F0
         BNE NOHEADER
         LDA BLKBUF+4
         AND #$0F
         BEQ NOHEADER
         STA LENGTH
DISPL:
         LDA BLKBUF+5,X
         ORA #$80
         JSR COUT
         INX
         CPX LENGTH
         BNE DISPL
         RTS
NOHEADER:
         JMP DISPMSG

; generate Apple-ASCII string (with MSB set)
.MACRO   ASCHI STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) | $80
.ENDREP
.ENDMACRO

; generated string with inverted Apple character
.MACRO   ASCINV STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) & $3F
.ENDREP
.ENDMACRO

MSGS:

NOHDR:     
         ASCHI   "---"
        .BYTE 0

CARDMSG:     
         ASCHI   "CARD 1:"
        .BYTE 0

A2FOREVER:
         ASCINV  "  APPLE II FOREVER!"
        .BYTE 0

VOLSEL:     
         ASCINV  "DAN II VOLUME SELECTOR"
	.BYTE 0

GOTOROW:
         STA CV          ; set row
         LDA #0
         STA CH          ; set column to 0
         JMP VTAB

DISPTITLE:
         PHA             ; remember message address
         LDA CV          ; remember row
         PHA
         LDX #$26        ; clear 39 characters ($00-$26)
LOOPLINE:
         LDA #$20        ; inverse space
         JSR COUT
         DEX
         BPL LOOPLINE

         PLA
         JSR GOTOROW     ; restore row
         LDA #8          ; center title message horizontally
         STA CH
         PLA             ; get message address
         TAX
         JMP DISPMSG

CARDMS1: LDA #'2'+128
         STA CARDMSG+5
CARDMS0:
         LDX #(CARDMSG-MSGS)
DISPMSG: LDA MSGS,X
         BEQ RTSL
         JSR COUT
         INX
         BNE DISPMSG
BUFLOC:
         LDA #<BLKBUF    ; store buffer location    
         STA BUFLO
         LDA #>BLKBUF
         STA BUFHI
RTSL:    RTS

READB:
         LDA #$01        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         LDA #$02        ; which block (in this example $0002)
         STA BLKLO
         LDA #$00
         STA BLKHI
         JMP INSTRUC

SETVOLW: LDA #$07        ; set volume but write to EEPROM
         BNE SETVOLC
SETVOL:
         LDA #$06        ; set volume dont write to EEPROM
SETVOLC:
         STA COMMAND
         JSR BUFLOC      ; dummy buffer location
         LDA VOLDRIVE0
         STA BLKLO
         LDA VOLDRIVE1
         STA BLKHI
         JMP INSTRUC

GETVOL:
         LDA #$05        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         JSR INSTRUC
         LDA BLKBUF
         STA GVOLDRIVE0
         LDA BLKBUF+1
         STA GVOLDRIVE1
         RTS

REBOOT:
         JSR HOME        ; clear screen
         LDA #$00        ; store zero byte at $F1
         STA LOWBT
         JMP (LOWBT)     ; jump back and reboot       

; Bootloader v4
; by DL Marks, TC Brehm
; - 2 block bootloader (1024 byte)
; - improved GUI with top/bottom title bars
; - highlighted volume selection
; - cursor key controls

; build for simulator debugging (running without DANII card hardware)
;SIM_DEBUG = 1

; standalone debugging (loading bootpg as a file from a disk)
;FILE_DEBUG = 1

INSTRUC    = $F0
LOWBT      = $F1
HIGHBT     = $F2
RTSBYT     = $F3
VOLDRIVE0  = $F5
VOLDRIVE1  = $F6
GVOLDRIVE0 = $F7
GVOLDRIVE1 = $F8
LENGTH     = $F9
CARD       = $FA
VOL        = $FB

BLKBUF = $1000

COMMAND = $42
UNIT    = $43
BUFLO   = $44
BUFHI   = $45
BLKLO   = $46
BLKHI   = $47

; APPLE II ROM constants
; zero page
CH       = $24
CV       = $25
BASL     = $28
BASH     = $29
INVFLG   = $32
; ROM routines
SLOOP    = $FABA
HOME     = $FC58
PRHEX    = $FDE3
PRBYTE   = $FDDA
RDKEY    = $FD0C
COUT     = $FDED
VTAB     = $FC22
SETVID   = $FE93
SETKBD   = $FE89
WAITLOOP = $FCA8
BELL     = $FBE2

; APPLE II hardware constants
SPKR     = $C030
; keyboard
KEY_LEFT      =  8+128
KEY_RIGHT     = 21+128
KEY_DOWN      = 10+128
KEY_UP        = 11+128
KEY_SPACE     = 32+128
KEY_BACKSPACE = 127+128
KEY_TAB       =  9+128
KEY_RETURN    = 13+128
KEY_ESC       = 27+128
KEY_COMMA     = ','+128
; display properties
FLASHING = $40
INVERSE  = $00
NORMAL   = $80

; number of blocks this boot program covers (1 block=512 bytes)
BLOCK_COUNT = (BOOT_END - START + 511)/512

         .ORG $800       ; bootloaders are loaded to this address

START:
         NOP
.IFDEF FILE_DEBUG        ; this is just for debugging, when loading the program from a file
         LDA #$70        ; slot 7
         STA UNIT
         LDA #13+128     ; load bootpg command
         STA COMMAND
         LDA #$08        ; address 0x800
         STA BUFHI
         LDA #$00
         STA BUFLO
         STA BLKHI       ; block $0000
         STA BLKLO
.ENDIF
         LDA #$20        ; JSR instruction
.IFDEF SIM_DEBUG         ; This is just for debugging, when running the program in a simulator (rather than on hardware).
         LDA #$60        ; use RTS instead of JSR instruction, so any call for commands just do nothing
.ENDIF
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
         STY LOWBT       ; store 0
         DEY             ; make zero a $FF
         LDA (LOWBT),Y   ; get low byte of address
         STA LOWBT       ; place at low byte

.IFNDEF FILE_DEBUG       ; skip loading additional blocks when debugging
         ; Load additional blocks: the ROM routine only loaded the first block/512 byte.
         ; Since the first 512byte we were just loaded by the ROM:
         ; - BLK is still set to $0000 and BUF is set to $0800
         ; - command is still set to the "load bootloader" command
         ; So we just need to update the address/block numbers...
         LDA #(BLOCK_COUNT-1); number of remaining blocks
         STA LENGTH
LOADBLOCKS:
         INC BLKLO       ; next block number
         INC BUFHI       ; advance buffer address by $0200
         INC BUFHI
         JSR INSTRUC     ; load the block
         BCC LOADOK      ; success?
         JSR BELL        ; oh no, we're doomed!
         JMP SLOOP       ; try another boot device
LOADOK:
         DEC LENGTH
         BNE LOADBLOCKS  ; load remaining blocks
.ENDIF
         LDA #<BLKBUF    ; store buffer location
         STA BUFLO
         LDA #>BLKBUF
         STA BUFHI

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
         LDY GVOLDRIVE0
         JSR DISPVOLUME  ; show item number and volume name
         LDA #$FF
         STA INVFLG

         LDA UNIT
         ORA #$80        ; check SD-card 2 (drive 1)
         STA UNIT        ; set high bit to get drive 1
         LDA #20         ; start at column 20
         LDY GVOLDRIVE1
         JSR DISPVOLUME  ; show item number for volume
         LDA #$FF
         STA INVFLG
         LSR A
         AND UNIT        ; clear high bit
         STA UNIT

         INC CV          ; go to next row
         INC VOL         ; go to next volume
         LDA VOL
         CMP #$10
         BCC UNITLOOP

VANITY:
         JSR PREVIOUS_VOLUMES ; load default value (previously selected volumes)
         JSR SETVOL           ; restore current volume selection (user aborts or presses RESET)
         JSR DISPCUR          ; show current volume numbers

GETVL:
         JSR ASKVOL           ; ask for new user selection
         JSR SETVOLW          ; write user selection
         JMP REBOOT

PREVIOUS_VOLUMES:
         LDA GVOLDRIVE0 ; load default value (currently selected drive)
         STA VOLDRIVE0
         LDA GVOLDRIVE1
         STA VOLDRIVE1
         RTS

DISPCUR:                 ; show current volume numbers
         LDA #21         ; row 21
         JSR GOTOROW
         JSR CARDMS0
         LDA #10
         STA CH
         LDA VOLDRIVE0
         JSR DVHEX

         LDA #20
         STA CH
         JSR CARDMS1
         LDA #30
         STA CH
         LDA VOLDRIVE1
         JMP DVHEX

ABORT:
         JSR WIPE_SELECTION   ; clear selected volumes
         JSR PREVIOUS_VOLUMES ; restore previous volume selection
         JSR DISPCUR          ; show selected volume numbers
         PLA
         PLA
         CLC
         JMP REBOOT

; ask for volume selection(s)
ASKVOL:
         LDA #$00          ; start with selecting card 0
         STA CARD
GETHEX:
         LDX CARD          ; card is 0 or 1
         LDA #FLASHING     ; flashing style
         JSR HIGHLIGHT_LINE
         JSR SHOW_VOLNUM   ; show selected volume number
         JSR RDKEY
         PHA
         LDA #NORMAL       ; normal style
         LDX CARD
         LDY VOLDRIVE0,X
         JSR HIGHLIGHT_LINE
         PLA
         LDX CARD          ; current card in X
         LDY VOLDRIVE0,X   ; current volume selection in Y
         CMP #13+128       ; RETURN key
         BNE NORET
RETKEY:
         LDX CARD
         BEQ TOGGLE_CARD
         RTS
NORET:
         CMP #KEY_ESC      ; ESCAPE key
         BEQ ABORT
         CMP #'!'+128      ; is !
         BNE NO_SPCASE
         LDA #$FF
         STA VOLDRIVE0
         RTS
NO_SPCASE:
         CMP #KEY_COMMA    ; when no up arrow is present
         BEQ UP
         CMP #KEY_UP       ; arrow up
         BNE NO_UP
UP:      DEY
         BMI WRAP
NO_UP:
         CMP #KEY_SPACE    ; space bar: DOWN
         BEQ DOWN
         CMP #KEY_DOWN     ; arrow down
         BNE NO_DOWN
DOWN:    INY
         CPY #$10
         BCC NO_DOWN
WRAP:
         PHA
         TYA
         AND #$0f
         TAY
         PLA
NO_DOWN:
         STY VOLDRIVE0,X   ; save current volume selection
         CMP #KEY_LEFT     ; left arrow?
         BEQ TOGGLE_CARD   ; select other card
         CMP #KEY_RIGHT    ; right arrow?
         BNE NO_TOGGLE
TOGGLE_CARD:
         LDA #INVERSE      ; inverse style
         JSR HIGHLIGHT_LINE
         LDA CARD
         EOR #$01
         STA CARD
         BPL GETHEX_FAR    ; unconditinal branch
NO_TOGGLE:
         CMP #'a'+128      ; lower case letters?
         BCC NOLOWER
         SEC
         SBC #$20
NOLOWER:
         CMP #'A'+128
         BCC NOLET
         CMP #'F'+128+1
         BCS NOLET
         SEC
         SBC #7
         BNE SELECT        ; unconditional branch
NOLET:   CMP #'0'+128
         BCC GETHEX_FAR
         CMP #'9'+128+1
         BCS GETHEX_FAR
SELECT:
         AND #$0F
         STA VOLDRIVE0,X
         JSR SHOW_VOLNUM
         JMP RETKEY
GETHEX_FAR:
         JMP GETHEX

DVHEX:   CMP #$FF
         BEQ DSPEC
         JMP PRHEX
DSPEC:
         LDA #'!'+128
         JMP COUT

SHOW_VOLNUM:
         LDX CARD          ; card 0 or 1?
         LDY VOLDRIVE0,X   ; Y position: 0-15
         LDX #10           ; X position: left half of screen
         LDA CARD
         BEQ SHOW_VOL_SELECT
         LDX #30           ; X position: right half of screen
SHOW_VOL_SELECT:
         STX CH            ; store X position
         LDY #16+5         ; Y row where to show the card selection
         STY CV
         JSR VTAB
         LDY CARD
         LDA VOLDRIVE0,Y   ; get volume selection for this card
         JSR DVHEX
         DEC CH
         RTS

DISPVOLUME:                ; display volume number/name
         STA CH
         LDA VOL           ; print hex digit for row
         PHA
         JSR PRHEX
         LDA #':'+128
         JSR COUT          ; print ":"
         INC CH            ; skip space
         STY LENGTH        ; scratch
         PLA
         CMP LENGTH
         BNE NOINVFLG
         LDA #$3F
         STA INVFLG        ; enable inverse printing of selected volume name
NOINVFLG:
         JSR READB         ; read a block from drive 0
DISPNAME:
         BCS NOHEADER      ; didn't read a sector
         LDA BLKBUF+5      ; if greater than $80 not a valid ASCII
         BMI NOHEADER
         LDA BLKBUF+4      ; look at volume directory header byte
         TAX
         AND #$F0
         CMP #$F0
         BNE NOHEADER
         TXA
         AND #$0F
         BEQ NOHEADER
         STA LENGTH
         LDX #0
DISPL:
         LDA BLKBUF+5,X
         ORA #NORMAL
         JSR COUT
         INX
         CPX LENGTH
         BNE DISPL
FILL_NXT:CPX #$0F          ; fill with spaces until 16 characters are written
         BNE FILL
         RTS
FILL:    LDA #' '+128
         JSR COUT
         INX
         BNE FILL_NXT      ; unconditional branch
NOHEADER:
         LDX #(NOHDR-MSGS)
         JMP DISPMSG

HIGHLIGHT_LINE:
         STA LENGTH        ; store display mode in scratch register
         TXA
         BEQ SHOW_CARD0
         LDA #20           ; show in right half of the screen
SHOW_CARD0:
         CLC
         ADC #$03          ; move by 3 characters to skip to the volume name display
         STA CH            ; store cursor X position
         LDA VOLDRIVE0,X
         BMI NO_SHOW       ; Y>=128? don't highlight anything (wide mode "!" selected)
         ADC #$03          ; Y-offset
         STA CV            ; store cursor Y position
         JSR VTAB          ; calculate screen address
         LDY CH            ; load cursor Y position
         LDX #$0E          ; load number of characters
LOOP_LINE:
         LDA (BASL),Y
         AND #$3F
         ORA LENGTH
         STA (BASL),Y
         INY
         DEX
         BPL LOOP_LINE
NO_SHOW:
         RTS

; generate Apple-ASCII string (with MSB set)
.MACRO   ASCHI STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) | NORMAL
.ENDREP
.ENDMACRO

; generated string with inverted characters
.MACRO   ASCINV STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) & $3F
.ENDREP
.ENDMACRO

MSGS:

NOHDR:
         ASCHI   "---            "
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

OKMSG:  ASCHI " OK!"
       .BYTE 0

ERRMSG: ASCHI "ERROR!"
       .BYTE $87,$87,$87,0 ; beep on error

GOTOROW:
         STA CV            ; set row
         LDA #0
         STA CH            ; set column to 0
         JMP VTAB

DISPTITLE:
         PHA               ; remember message address
         LDX #$26          ; clear 39 characters ($00-$26)
LOOPLINE:
         LDA #$20          ; inverse space
         JSR COUT
         DEX
         BPL LOOPLINE

         PLA               ; get message address
         TAX
         LDA #8            ; center title message horizontally
         STA CH
         BNE DISPMSG       ; unconditional jump

CARDMS1: LDA #'2'+128
         STA CARDMSG+5
CARDMS0:
         LDX #(CARDMSG-MSGS)
DISPMSG: LDA MSGS,X
         BEQ RTSL
         JSR COUT
         INX
         BNE DISPMSG
RTSL:    RTS

READB:
         LDY #$00
         STY BLKHI
         INY               ; Y=1: read block
         STY COMMAND       ; store at $42
         INY               ; Y=2: which block (in this example $0002)
         STY BLKLO
         JMP INSTRUC

SETVOLW: LDA #$07          ; set volume but write to EEPROM
         BNE SETVOLC
SETVOL:
         LDA #$06          ; set volume dont write to EEPROM
SETVOLC:
         STA COMMAND
         LDA VOLDRIVE0
         STA BLKLO
         LDA VOLDRIVE1
         STA BLKHI
         JMP INSTRUC

GETVOL:
.IFDEF SIM_DEBUG
         LDA #$02          ; just for sim testing without hardware
         STA BLKBUF
         LDA #$04
         STA BLKBUF+1
.ENDIF
         LDA #$05          ; read block
         STA COMMAND       ; store at $42
         JSR INSTRUC
         LDA BLKBUF
         STA GVOLDRIVE0
         LDA BLKBUF+1
         STA GVOLDRIVE1
         RTS

SHOW_SELECTION:            ; highlight selected volume names
         LDA #INVERSE      ; inverse display
         BEQ UPDATE_SELECTION
WIPE_SELECTION:            ; normal display of selected volume names
         LDA #NORMAL
UPDATE_SELECTION:
         PHA               ; save display style
         LDX #$00          ; card 0
         JSR HIGHLIGHT_LINE
         PLA               ; restore display style
         LDX #$01          ; card 0
         JMP HIGHLIGHT_LINE

REBOOT:
         PHP
         JSR SHOW_SELECTION; show current selection
         LDA #22           ; show ok/error in row 22
         JSR GOTOROW
         LDA #17           ; center horizontally
         STA CH
         PLP
         LDX #(OKMSG-MSGS)
         BCC SHOW_MSG
         LDX #(ERRMSG-MSGS)
SHOW_MSG:
         JSR DISPMSG
         LDX #$06          ; now wait a bit, showing the configuration
DELAY:
         LDA #$FF
         JSR WAITLOOP
         DEX
         BNE DELAY

         JSR HOME          ; clear screen
.IFDEF SIM_DEBUG
STOP:    JMP STOP
.ELSE
         LDA #$00          ; store zero byte at $F1
         STA LOWBT
         JMP (LOWBT)       ; jump back and reboot
.ENDIF
BOOT_END:

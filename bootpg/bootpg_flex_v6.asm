; Bootloader v6
; by DL Marks, TC Brehm
; - 2 block bootloader (1024 byte)
; - improved GUI with top/bottom title bars
; - highlighted volume selection
; - cursor key controls
; - IP address configuration (for Wiznet)
; - flexible volume selection

; build for simulator debugging (running without DANII card hardware)
;SIM_DEBUG = 1

; standalone debugging (loading bootpg as a file from a disk)
;FILE_DEBUG = 1

; row where to start showing the volume names
MENU_ROW   = 4

INSTRUC    = $F0
LOWBT      = $F1
HIGHBT     = $F2
RTSBYT     = $F3
VOLDRIVE0  = $F5
VOLDRIVE1  = $F6
GVOLDRIVE0 = $F7
GVOLDRIVE1 = $F8
SCRATCH    = $F9
DRIVE      = $FA
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
AUTO     = $01

; number of blocks this boot program covers (1 block=512 bytes)
BLOCK_COUNT = (BOOT_END - START + 511)/512

.IFDEF FILE_DEBUG 
         .ORG $2000
.ELSE
         .ORG $800       ; bootloaders are loaded to this address
.ENDIF

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
         LDA #$60        ; use RTS instead of JSR instruction, so any command calls just do nothing
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
         STA SCRATCH
LOADBLOCKS:
         INC BLKLO       ; next block number
         INC BUFHI       ; advance buffer address by $0200
         INC BUFHI
         JSR INSTRUC     ; load the block
         BCC LOADOK      ; success?
         JSR BELL        ; oh no, we're doomed!
         JMP SLOOP       ; try another boot device
LOADOK:
         DEC SCRATCH     ; number of remaining blocks
         BNE LOADBLOCKS  ; load remaining blocks
.ENDIF
         JSR SETVID           ; set to IN#0/PR#0 just in case
         JSR SETKBD
         JSR SHOW_TITLE       ; show header/footer lines
         JSR SHOWSD
         JSR DAN_GETVOL       ; get volume numbers
         JSR DISPCUR          ; show current volume numbers
         JSR SHOWVOLNAMES
         JSR PREVIOUS_VOLUMES ; load default value (previously selected volumes)
         JSR DAN_SETVOL       ; restore current volume selection (user aborts or presses RESET)
         JSR SHOWIP           ; show FTP/IP configuration, if applicable
         JSR ASKVOL           ; ask for new user selection
         JSR DAN_SETVOLW      ; write user selection
         JMP REBOOT

SHOWVOLNAMES:
         LDA #0
         STA VOL         ; set drive number
         LDA #MENU_ROW
         STA CV          ; set screen row
UNITLOOP:
         JSR VTAB

         LDA VOL         ; set both drives to location
         STA VOLDRIVE0   ; select volume #VOL on SD1
         ORA #$80        ; select volume #VOL on SD2
         STA VOLDRIVE1
         JSR DAN_SETVOL

         LDA #0          ; start at column 0
         JSR DISPVOLUME  ; show item number and volume name
         LDA #$FF
         STA INVFLG

         LDA UNIT
         ORA #$80        ; check SD-card 2 (drive 1)
         STA UNIT        ; set high bit to get drive 1
         LDA VOL
         ORA #$80        ; indicate SD2
         STA VOL
         LDA #20         ; start at column 20
         JSR DISPVOLUME  ; show item number for volume
         LDA #$FF
         STA INVFLG
         LSR A
         AND UNIT        ; clear high bit
         STA UNIT

         INC CV          ; go to next row
         INC VOL         ; go to next volume
         LDA VOL
         AND #$7F        ; clear SD2 bit
         STA VOL
         CMP #$10
         BCC UNITLOOP
         RTS

PREVIOUS_VOLUMES:
         LDA GVOLDRIVE0       ; load default value (currently selected drive)
         STA VOLDRIVE0
         LDA GVOLDRIVE1
         STA VOLDRIVE1
         RTS

SHOWSD:
         LDY #$00
         STY CH
         LDY #$03
         STY CV
         JSR VTAB
         JSR SD1MSG
         LDY #20
         STY CH
         JMP SD2MSG

DISPCUR:                 ; show current volume numbers
         LDA #21         ; row 21
         JSR GOTOROW
         JSR DRVMSG0
         LDA #20
         STA CH
         JSR DRVMSG1
         LDA #$01            ; show selection for drives 1+0
         STA DRIVE
:        JSR SHOW_VOLNUM
         DEC DRIVE
         BPL :-              ; both drives displayed?
         RTS

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
         STA DRIVE
GETHEX:
         LDA #FLASHING     ; show current drive selection with flashing style
         JSR REDRAW_LINE
         JSR SHOW_VOLNUM   ; show selected volume number
         JSR RDKEY
         PHA
         LDA #AUTO         ; show current drive selection, use automatic style
         JSR REDRAW_LINE
         PLA
         LDX DRIVE         ; current card in X
         LDY VOLDRIVE0,X   ; current volume selection in Y
         CMP #13+128       ; RETURN key
         BNE NORET
RETKEY:
         LDA #INVERSE      ; show current drive selectiuon in inverse style
         JSR REDRAW_LINE
         LDA DRIVE
         EOR #$01
         STA DRIVE
         BNE GETHEX
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
UP:      TYA
         ASL A             ; shift volume flag into carry
         PHP               ; save flags
         SEC
         SBC #$02
         AND #$1E
         PLP               ; restore flags with carry for drive
         ROR A             ; shift drive flag back into register
         TAY
UPDATE_LINE:
         TYA
         AND #$8f          ; wrap on overflow
         STA VOLDRIVE0,X   ; save current volume selection
         JMP GETHEX
NO_UP:
         CMP #KEY_SPACE    ; space bar: DOWN
         BEQ DOWN
         CMP #KEY_DOWN     ; arrow down
         BNE NO_DOWN
DOWN:    INY
         BNE UPDATE_LINE   ; unconditional branch
NO_DOWN:
         CMP #KEY_LEFT     ; left arrow?
         BEQ TOGGLE_CARD   ; select other card
         CMP #KEY_RIGHT    ; right arrow?
         BNE NO_TOGGLE
TOGGLE_CARD:
         TYA
         EOR #$80          ; toggle card
         STA VOLDRIVE0,X   ; save updated selection
         BPL GETHEX_FAR    ; unconditional branch
NO_TOGGLE:
         CMP #'a'+128      ; lower case letters?
         BCC NOLOWER
         SEC
         SBC #$20          ; convert to uppercase
NOLOWER:
         CMP #'A'+128
         BCC NOLET
         CMP #'F'+128+1
         BCS NOLET
         SEC
         SBC #7
         BNE SELECT        ; unconditional branch
NOLET:   CMP #'0'+128
         BCC NONUM
         CMP #'9'+128+1
         BCS NONUM
SELECT:
         AND #$0F
         STA SCRATCH
         TYA               ; get current selection
         AND #$80          ; mask SD card bit
         ORA SCRATCH
         STA VOLDRIVE0,X
         JSR SHOW_VOLNUM
         JMP RETKEY
NONUM:
         CMP #'I'+128      ; FTP/IP configuration with (I)P
         BEQ IPCONFIG
GETHEX_FAR:
         JMP GETHEX
IPCONFIG:
         JSR SHOW_TITLE
         JSR SHOWIP       ; show current IP address
         JMP NEWIP        ; enter new IP address

DVHEX:   CMP #$FF
         BEQ DSPEC
         JMP PRHEX
DSPEC:
         LDA #'!'+128
         JMP COUT

SHOW_TITLE:
         JSR HOME        ; clear screen
         LDA #(VOLSEL-MSGS) ; show title
         JSR DISPTITLE
         LDA #23
         JSR GOTOROW
         LDA #(A2FOREVER-MSGS) ; show title
         JMP DISPTITLE

SHOW_VOLNUM:
         LDX #11           ; X position: left half of screen
         LDA DRIVE         ; drive 0 or 1?
         BEQ SHOW_VOL_SELECT
         LDX #31           ; X position: right half of screen
SHOW_VOL_SELECT:
         STX CH            ; store X position
         LDY #16+5         ; Y row where to show the volume selection
         STY CV
         JSR VTAB
         LDY DRIVE
         LDA VOLDRIVE0,Y   ; get volume selection for this drive
         PHA
         LDY #$01          ; SD1
         ASL A
         BCC :+
         INY               ; SD2
:        TYA
         JSR DVHEX
         LDY CH
         INY
         STY CH
         PLA
         JSR DVHEX
         DEC CH
         RTS

DISPVOLUME:                ; display volume number/name
         STA CH
         LDA VOL           ; print hex digit for row
         PHA               ; remember volume
         AND #$7F          ; clear SD2 bit
         JSR PRHEX
         LDA #':'+128
         JSR COUT          ; print ":"
         INC CH            ; skip space
         PLA               ; restore volume
         CMP GVOLDRIVE0
         BEQ SETINV
         CMP GVOLDRIVE1
         BNE NOINVFLG
SETINV:
         LDA #$3F
         STA INVFLG        ; enable inverse printing of selected volume name
NOINVFLG:
         JSR DAN_READBLOCK ; read a block from drive 0
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
         STA SCRATCH       ; length
         LDX #0
DISPL:
         LDA BLKBUF+5,X
         ORA #NORMAL
         JSR COUT
         INX
         CPX SCRATCH       ; check length
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

REDRAW_LINE:
         LDX DRIVE
         CMP #AUTO         ; automatic display mode?
         BNE REDRAW1

         LDA #NORMAL       ; use normal text mode to wipe selection
         LDY VOLDRIVE0     ; check if both drives have identical selection
         CPY VOLDRIVE1
         BNE REDRAW1       ; not identical?
         LDA #INVERSE      ; identical: use inverse text font, since vol is still selected

REDRAW1: 
         STA SCRATCH       ; save display mode
         LDA VOLDRIVE0,X   ; load volume selection
         BMI :+            ; is a volume on card 2 is selected?
         LDY #3
         BNE SHOW_CARD0    ; unconditional branch
:        LDY #23           ; show in right half of the screen
SHOW_CARD0:
         STY CH            ; store cursor X position
         AND #$0F          ; mask volume number
         CLC
         ADC #MENU_ROW     ; Y-offset
         STA CV            ; store cursor Y position
         JSR VTAB          ; calculate screen address
         LDY CH            ; load cursor Y position
         LDX #$0E          ; load number of characters
LOOP_LINE:
         LDA (BASL),Y
         AND #$3F
         ORA SCRATCH
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

DRIVEMSG:
         ASCHI   "DRIVE 1: SD?/"
        .BYTE 0

SDMSG:   ASCHI   "SD1:"
        .BYTE 0

A2FOREVER:
         ASCINV  "  APPLE II FOREVER!  V"
         .BYTE '0'+FW_MAJOR
         ASCINV "."
         .BYTE '0'+FW_MINOR
         ASCINV "."
         .BYTE '0'+FW_MAINT
         .BYTE 0

VOLSEL:
         ASCINV  "DAN II VOLUME SELECTOR"
	.BYTE 0

OKMSG:  ASCHI " OK!"
       .BYTE 0

ERRMSG: ASCHI "ERROR!"
       .BYTE $87,$87,$87,0 ; beep on error
IPMSG:  ASCHI "FTP/IP: "
       .BYTE 0
NEWIPMSG:ASCHI "NEW IP:    .   .   .   "
       .BYTE 0

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
         BNE DISPMSG       ; unconditional branch

SD2MSG:  LDA #'2'+128
         STA SDMSG+2
SD1MSG:  LDX #(SDMSG-MSGS)
         BNE DISPMSG       ; unconditional branch

DRVMSG1: LDA #'2'+128
         STA DRIVEMSG+6
DRVMSG0:
         LDX #(DRIVEMSG-MSGS)
DISPMSG: LDA MSGS,X
         BEQ RTSL
         JSR COUT
         INX
         BNE DISPMSG
RTSL:    RTS

DAN_READBLOCK:
         LDY #$00
         STY BLKHI
         INY               ; Y=1: read block
         STY COMMAND       ; store at $42
         INY               ; Y=2: which block (in this example $0002)
         STY BLKLO
         JMP DAN_COMM

DAN_SETVOLW:
         LDA #$07          ; set volume but write to EEPROM
         BNE DAN_VOLCMD
DAN_SETVOL:
         LDA #$06          ; set volume dont write to EEPROM
DAN_VOLCMD:
         STA COMMAND
         LDA VOLDRIVE0
         STA BLKLO         ; DRIVE 0: firmware expects 0-7f=volumes on SD1, 0x80-0xfe=volumes on SD2
         LDA VOLDRIVE1
         EOR #$80          ; DRIVE 1: flip MSB - since the firmware expects 0-7f=volumes on SD2, 0x80-0xfe=volumes on SD1
         STA BLKHI
DAN_COMM:
         LDA #<BLKBUF      ; store buffer location
         STA BUFLO
         LDA #>BLKBUF
         STA BUFHI
         JMP INSTRUC

DAN_GETVOL:
.IFDEF SIM_DEBUG
         LDA #$02          ; just for sim testing without hardware
         STA BLKBUF
         LDA #$04
         STA BLKBUF+1
.ENDIF
         LDA #$05          ; read block
         STA COMMAND       ; store at $42
         JSR DAN_COMM
         LDA BLKBUF
         STA GVOLDRIVE0
         LDA BLKBUF+1
         EOR #$80          ; flip MSB for drive 2 - since the firmware provides 0-$7f=volumes on SD2, $80-$fe=volumes on SD1
                           ; but bootpg uses 0-$7f=volumes on SD1, $80-$fe=volumes on SD2
         STA GVOLDRIVE1
         JMP PREVIOUS_VOLUMES ; set default values

SHOWIP:
         LDA #$21          ; get IP configuration
         JSR DAN_VOLCMD
         BCS RTSL
         LDA BLKBUF+16     ; get FTP/IP state
         BEQ RTSL
         LDA #$01
         JSR GOTOROW
         LDX #$09
         STX CH
         LDX #(IPMSG-MSGS)
         JSR DISPMSG

         LDA BLKBUF+6      ; show first byte of IP address
         JSR PRIPDOT

         LDA BLKBUF+7      ; second byte
         JSR PRIPDOT

         LDA BLKBUF+8      ; third byte
         JSR PRIPDOT
         
         LDA BLKBUF+9      ; last byte
         JMP PRDEC

NEWIP:
         LDA UNIT
         PHA               ; remember original UNIT value
:
         LDA #10
         JSR GOTOROW
         LDX #(NEWIPMSG-MSGS)
         JSR DISPMSG
         LDA #8
         STA CH
         JSR READINT       ; first byte of IP address
         BCS :-
         STA BUFLO
         INC CH
         JSR READINT       ; second byte of IP address
         BCS :-
         STA BUFHI
         INC CH
         JSR READINT       ; third byte of IP address
         BCS :-
         STA BLKLO
         INC CH
         JSR READINT       ; fourth byte of IP address
         BCS :-
         STA BLKHI
         STA UNIT          ; also use the last digit as the last byte of the MAC address (avoid conflict when using multiple WIZnets)
SETIP:
         LDA #$20          ; set IP configuration
         STA COMMAND
         JSR INSTRUC
         CLC               ; ignore carry/error flag (since this command returns 1 on success)
         TAX
         PLA
         STA UNIT          ; restore original UNIT value
         DEX
         BEQ IPCFGOK       ; check if return code was 1
         SEC               ; set carry to indicate error
IPCFGOK:
         JMP SHOW_CFG_RESULT

READINT:                   ; read a byte as a decimal integer
         LDA #$00
         STA SCRATCH       ; current value
         LDX #$03          ; we need 3 decimal digits
RDNEXT:
         TXA
         PHA
         JSR GETDIGIT      ; get a single digit
         BCS OVERFLW       ; abort?
         CMP #$FF          ; returns $FF to indicate a SPACE/RETURN key was pressed
         BEQ RDSKIP        ; skip the other digits
         TAY
         JSR TIMES10
         BCS OVERFLW       ; overflow? Bad input - exceeds a byte...
         TYA
         ADC SCRATCH
         STA SCRATCH
         BCS OVERFLW       ; overflow? Bad input - exceeds a byte...
         PLA
         TAX
         DEX
         BNE RDNEXT        ; another digit to read?
         PHA
OVERFLW:
         PLA
RETBYTE:
         LDA SCRATCH       ; load the result
         RTS
RDSKIP:
         PLA
         CLC
         ADC CH            ; move cursor, skipped the missing digits
         STA CH
         BCC RETBYTE       ; unconditional jump

TIMES10: LDX #$0A          ; multiply the current input byte by 10
         LDA #$00
         CLC
LOOP10:  ADC SCRATCH
         BCS T10OVFL       ; exceeding a single byte? overflow...
         DEX
         BNE LOOP10        ; add 10 times (x10)
         STA SCRATCH
T10OVFL: RTS

GETDIGIT:                  ; read a single digit from the keyboard
         JSR RDKEY
         CMP #' '+128
         BNE NOSP
DIGITDONE:                 ; when user entered less than 3 digits (space/dot/RETURN)
         LDA #$FF
         CLC
         RTS
NOSP:
         CMP #13+128
         BEQ DIGITDONE
         CMP #'.'+128
         BEQ DIGITDONE
         CMP #'0'+128
         BMI GETDIGIT
         CMP #'9'+1+128
         BCS GETDIGIT
         JSR COUT
         AND #$0F
         RTS

PRIPDOT:                   ; print decimal byte, followed by a "."
         JSR PRDEC
         LDA #'.'+128
         JMP COUT

SHOW_SELECTION:            ; highlight selected volume names
         LDA #INVERSE      ; inverse display
         BEQ UPDATE_SELECTION ; unconditional branch
WIPE_SELECTION:            ; normal display of selected volume names
         LDA #NORMAL       ; show drive selection in normal text (wipes selection)
UPDATE_SELECTION:
         PHA               ; save display style
         LDX #$00          ; drive 1
         STX DRIVE
         JSR REDRAW_LINE
         PLA               ; restore display style
         INC DRIVE         ; drive 2
         JMP REDRAW_LINE

REBOOT:
         PHP
         JSR SHOW_SELECTION; show current selection
         LDA #22           ; show ok/error in row 22
         JSR GOTOROW
         LDA #17           ; center horizontally
         STA CH
         PLP
SHOW_CFG_RESULT:
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
:        JMP :-            ; loop forever
.ELSE
         LDA #$08          ; push return address $0800 to the stack
         PHA
         STA BUFHI         ; also store $800 in BUF address
         LDA #$00          ; take care of lower byte
         PHA
         STA BUFLO
         STA BLKLO         ; always load block 0
         STA BLKHI
         LDX #$01
         STA (BUFLO,X)     ; write "BRK" to $801, so if loading fails (volume does not exist, it breaks to monitor immediately)
         LDA #10           ; "failsafe load block" command
         STA COMMAND
         JMP (LOWBT)       ; jump, load boot sector and "return" to $800
.ENDIF

PRDEC:                     ; print decimal number (byte)
         CMP #10
         BCC PR1
         LDX #100
         STX SCRATCH
         JSR DECDIGIT
         CPX #$00
         BEQ PR10
         PHA
         TXA
         JSR PRHEX
         PLA
PR10:
         LDX #10
         STX SCRATCH
         JSR DECDIGIT
         PHA
         TXA
         JSR PRHEX
         PLA
PR1:    
         JMP PRHEX

DECDIGIT:
         LDX #$00
NEXTDEC:
         CMP SCRATCH
         BCC DECDONE
         INX
         SEC
         SBC SCRATCH
         BCS NEXTDEC
DECDONE:
         RTS

BOOT_END:

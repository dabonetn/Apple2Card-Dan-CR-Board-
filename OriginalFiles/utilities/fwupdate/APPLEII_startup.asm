; DAN][ controller Arduino firmware update utility: Apple II ProDOS startup.
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

; imported code labels
.import MAIN
.import DAN2_FWUPDATE

; exported code labels
.export CLEAR_WARMSTART
.export SET_WARMSTART
.export BEGIN

.setcpu "6502"

; include ROM routines for Apple II or III
.include "AppleROM.inc"

USR_DATA = $0320 ; space for user data
SOFTEV   = $03f2 ; vector for warm start
PWREDUP  = $03f4 ; this must = EOR #$A5 of SOFTEV+1

.SEGMENT "STARTUP"

BEGIN:
    JSR HOME
    JSR MAIN
    JMP PRODOS_QUIT

PRODOS_QUIT:
    jsr  $bf00     ; quit to PRODOS
    .byte  $65
    .byte  <parmquit
    .byte  >parmquit
parmquit:
    .byte  4, 0, 0, 0, 0, 0, 0

WARMSTART:
    lda USR_DATA+0  ; restore cursor position after warm start
    sta CV
    lda USR_DATA+1
    sta BASL
    lda USR_DATA+2
    sta BASH
    jmp DAN2_FWUPDATE

CLEAR_WARMSTART:    ; clear the warm start hook
    lda #$00
    sta PWREDUP
    sta SOFTEV
    sta SOFTEV+1
    rts

SET_WARMSTART:      ; install warm start hook
    lda CV          ; remember cursor position
    sta USR_DATA+0
    lda BASL
    sta USR_DATA+1
    lda BASH
    sta USR_DATA+2

    lda #<WARMSTART ; address of warm start hook
    sta SOFTEV      ; set lower address of hook
    lda #>WARMSTART
    sta SOFTEV+1    ; set upper address of hook
    eor #$A5        ; warm start magic byte
    sta PWREDUP     ; must match (SOFTEV+1)^$A5 to trigger warm start
    rts

.SEGMENT "INIT"
.SEGMENT "ONCE"

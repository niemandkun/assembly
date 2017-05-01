.model tiny
locals

.code
        org     100h
start:
        jmp     begin

include ringbuf.asm
include keybuf.asm
include sound.asm
include print.asm
include int9.asm

begin proc near

        call    setupVector

@@keyboardLoop:
        hlt
        xor     ax, ax
        call    ringBufferRead
        jc      @@keyboardLoop

        call    printKey
        call    printNewLine

        cmp     al, 81h
        je      @@esc

        call    putKey
        jc      @@loopFinish
        call    peekKey
        jc      @@noKeyPressed

        mov     bx, 80h
        mul     bx
        call    setSoundFreq
        call    soundOn

@@loopFinish:
        jmp     @@keyboardLoop

@@noKeyPressed:
        call    soundOff
        jmp     @@keyboardLoop

@@esc:
        call    soundOff
        call    restoreVector
        int     20h

begin endp


printKey proc near
        push    ax
        call    printByte
        pop     ax
        ret
printKey endp


end start

.model tiny
locals

.code
        org     100h
start:
        jmp     begin

include ringbuf.asm
include keybuf.asm
include print.asm
include sound.asm
include zelda.asm
include int9.asm

f12     dw      0

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

        cmp     al, 0D8h
        jne     @@play

        inc     word ptr [f12]
        cmp     word ptr [f12], 10
        jne     @@play
        mov     word ptr [f12], 0
        call    playZelda

@@play:
        call    putKey
        jc      @@loopFinish
        call    peekKey
        jc      @@noKeyPressed

        call    playNote

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


sword   db      "It's dangerous to go alone! Take this", 0Ah, 0Dh, 24h


playZelda proc c near uses ax bx cx dx si

        lea     dx, [sword]
        mov     ah, 09h
        int     21h

        xor     ax, ax
        call    setSoundFreq

        call    soundOn
        mov     si, offset zelda

@@playCycle:

        lodsw
        cmp     ax, 0ffffh
        je      @@finish

        mov     dx, ax

        xor     ax, ax
        lodsb

        sub     ax, 60
        add     ax, 24
        mov     cx, 2
        shl     ax, cl
        add     ax, 2
        add     ax, offset scale
        mov     bx, ax
        mov     ax, [bx]

        call    setSoundFreq

@@noteLoop:
        mov     cx, 0800h
@@1:
        loop    @@1
        dec     dx
        jg      @@noteLoop

        xor     ax, ax
        call    setSoundFreq

        mov     cx, 2000h
@@delayLoop:
        loop    @@delayLoop

        call    ringBufferRead
        jnc     @@finish

        jmp     @@playCycle

@@finish:
        call    soundOff
        ret

playZelda endp


end start

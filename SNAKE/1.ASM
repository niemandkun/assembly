        model   small
        locals

.stack

include string.asm
include args.asm
include ringbuf.asm
include int9.asm
include print.asm

text segment
        assume  cs:text, ds:text, es:text

handler:        ; смещения обработчиков для каждой команды
        dw      0,      offset exit
        dw      1,      offset keyUp
        dw      2,      offset keyRight
        dw      3,      offset keyLeft
        dw      4,      offset keyDown
        dw      0FFFFh

start:
        call    parseArgs

        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        call    setupVector

@@1:
        hlt
        call    ringBufferRead
        jc      @@1
        mov     si, offset handler
        xor     ah, ah
        mov     bx, ax
@@2:
        lodsw
        cmp     ax, 0FFFFh
        jz      @@1
        cmp     ax, bx
        jz      @@3
        add     si, 2
        jmp     @@2
@@3:
        lodsw
        call    ax
        jmp     @@1


exit proc near
        call    restoreVector
        mov     ah, 4ch
        int     21h
exit endp

keyUp proc near
        print
        ret
keyUp endp

keyDown proc near
        print
        ret
keyDown endp

keyLeft proc near
        print
        ret
keyLeft endp

keyRight proc near
        print
        ret
keyRight endp

text ends

end start

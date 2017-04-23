.model tiny
locals

.code
        org     100h

start:
        jmp     begin

include ringbuf.asm
include print.asm

old9:
old9segment dw ?
old9offset dw ?
escCount dw 0

int9 proc near
        push    ax
        in      al, 60h
        call    bufferWrite
        in      al, 61h
        or      al, 80h
        out     61h, al
        and     al, 7Fh
        out     61h, al
        mov     al, 20h
        out     20h, al
        pop     ax
        iret
int9 endp

begin proc near
        call    setupVector

@@printKeyLoop:
        hlt
        xor     ax, ax
        call    bufferRead
        jc      @@printKeyLoop

        push    ax
        call    printByte
        call    printNewLine
        pop     ax

        cmp     ax, 01h
        je      @@esc

        cmp     ax, 0E0h
        je      @@other

        and     ax, 80h
        test    ax, ax
        jnz     @@release

@@other:
        mov     escCount, 0
        jmp     @@printKeyLoop

@@release:
        mov     ah, 09h
        lea     dx, [separator]
        int     21h

        jmp     @@printKeyLoop

@@esc:
        inc     escCount
        cmp     escCount, 3
        jne     @@printKeyLoop

        call    restoreVector

        mov     ah, 09h
        lea     dx, [exitMessage]
        int     21h

        int     20h
begin endp

exitMessage     db  "exit", 0Dh, 0Ah, 24h
separator       db  "---", 0Dh, 0Ah, 24h

setupVector proc near
        push    di
        push    dx

        mov     ax, 3509h
        int     21h
        mov     ax, es
        push    cs
        pop     es

        lea     di, [old9]
        stosw
        mov     ax, bx
        stosw

        lea     dx, [int9]
        mov     ax, 2509h
        int     21h

        pop     dx
        pop     di
        ret
setupVector endp

restoreVector proc near
        mov     dx, word ptr cs:[old9offset]
        mov     bx, word ptr cs:[old9segment]
        mov     ds, bx
        mov     ax, 2509h
        int     21h
        push    cs
        pop     ds
        ret
restoreVector endp

end start

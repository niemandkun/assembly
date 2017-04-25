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
depth dw 1
lastKey dw ?

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

        mov     bx, ax

        cmp     bx, 81h
        je      @@esc
        cmp     bx, 01h
        je      @@compare
        mov     escCount, 0

@@compare:
        cmp     bx, 0E0h
        je      @@other
        and     ax, 80h
        test    ax, ax
        jz      @@press
        jmp     @@release

@@press:
        cmp     depth, 0
        je      @@pressPrintKey
        cmp     lastKey, bx
        je      @@pressRepeat
        lea     dx, [openSep]
        call    print
@@pressPrintKey:
        inc     depth
@@pressRepeat:
        mov     lastKey, bx
        call    printKey
        lea     dx, [spaceSep]
        call    print
        jmp     @@printKeyLoop

@@release:
        mov     lastKey, bx
        call    printKey
        dec     depth
        cmp     depth, 0
        je      @@releaseZeroDepth
        lea     dx, [closeSep]
        call    print
        jmp     @@printKeyLoop
@@releaseZeroDepth:
        lea     dx, [newlineSep]
        call    print
        jmp     @@printKeyLoop

@@other:
        call    printKey
        lea     dx, [spaceSep]
        call    print
        jmp     @@printKeyLoop

@@esc:
        inc     escCount
        cmp     escCount, 3
        jne     @@compare

@@finish:
        call    printKey
        call    restoreVector
        mov     ah, 09h
        lea     dx, [exitMessage]
        int     21h
        int     20h
begin endp

print proc near
        mov     ah, 09h
        int     21h
        ret
print endp

printKey proc near
        push    bx
        call    printByte
        pop     bx
        ret
printKey endp

exitMessage     db  0Dh, 0Ah, 0Dh, 0Ah, "exit", 0Dh, 0Ah, 24h
openSep         db  "< ", 24h
closeSep        db  " > ", 24h
spaceSep        db  " ", 24h
newlineSep      db  0Dh, 0Ah, 0Dh, 0Ah, 24h

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

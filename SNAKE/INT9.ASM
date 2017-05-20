text segment
        assume  cs:text, ds:text, es:text

old9:
old9segment dw ?
old9offset dw ?

keyCommands:
        ;
        ; convert scancode into command code
        ;
        db      01h,    0       ; exit
        db      50h,    1       ; up
        db      4Dh,    2       ; right
        db      4Bh,    3       ; left
        db      48h,    4       ; down
        db      0FFh,   0FFh    ; EOT


int9 proc near
        push    ax

        in      al, 60h
        call    getCommand
        cmp     al, 0FFh
        je      @@endOfInterrupt
        call    ringBufferWrite

@@endOfInterrupt:

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


getCommand proc near
        push    si
        push    bx
        push    ds

        mov     bx, ax

        mov     ax, cs
        mov     ds, ax

        lea     si, [keyCommands]

@@searchCycle:
        lodsb
        cmp     al, 0FFh
        je      @@finish

        cmp     al, bl
        je      @@finish

        inc     si
        jmp     @@searchCycle

@@finish:
        lodsb
        pop     ds
        pop     bx
        pop     si

        ret
getCommand endp


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

text ends

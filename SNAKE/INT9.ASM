old9:
old9segment dw ?
old9offset dw ?


int9 proc near
        push    ax
        in      al, 60h
        call    ringBufferWrite
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

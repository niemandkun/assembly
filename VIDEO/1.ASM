.model tiny
locals

.code
        org     100h

start:
        mov     ax, 0B800h
        mov     es, ax

        mov     ah, 00h
        mov     al, 03h
        ;mov     al, 04h
        ;mov     al, 13h
        int     10h

        mov     ah, 0B0h
        mov     al, "X"
        mov     di, (12 * 80 + 39) * 2
        ;mov     di, (12 * 40 + 19) * 2
        stosw

        ;xor     ax, ax
        ;int     33h

        ;mov     ax, 1
        ;int     33h

        ;stosw

        xor     ax, ax
        int     16h

        mov     ax, 03h
        int     10h

        ret

end start

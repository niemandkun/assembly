soundOn proc near
        in      al, 61h
        or      al, 00000011b
        out     61h, al
        ret
soundOn endp


soundOff proc near
        in      al, 61h
        and     al, 11111100b
        out     61h, al
        ret
soundOff endp


setSoundFreq proc near
        ; args:
        ;       ax - sound frequency
        ; ret:
        ;       none

        push    bx
        mov     bx, ax

        mov     al, 10110110b
        out     43h, al

        mov     ax, bx

        out     42h, al
        mov     al, ah
        out     42h, al

        pop     bx
        ret

setSoundFreq endp

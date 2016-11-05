        .model tiny
        .code
        org 100h
        locals
        .186

system=16

start:
        mov     ax, 57005
        mov     bx, system
        xor     cx, cx
@@1:
        xor     dx, dx
        div     bx
        push    dx
        inc     cx

        test    ax, ax
        jnz     @@1

        mov     ah, 02h
@@2:
        pop     dx
        cmp     dl, 10
        jb      @@3
        add     dl, 7
@@3:
        add     dl, 30h
        int     21h
        loop    @@2        ; if cx == 0, exit loop

        ret

end start

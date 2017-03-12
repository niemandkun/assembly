        .model tiny
        locals
        .code
        org     100h


start:
        xor     cx, cx

id_loop:
        xor     ax, ax
        mov     ah, cl
        push    cx

        int     2Fh

        test    al, al
        jz      id_loop_end

        mov     al, ah
        xor     ah, ah
        mov     bx, 10h
        mov     bp, 2
        call    printf

        mov     ah, 02h
        mov     dx, 68h                 ; "h"
        int     21h

        lea     dx, [id_found_msg]
        mov     ah, 09h
        int     21h

id_loop_end:
        pop     cx
        inc     cx
        cmp     cx, 100h
        jne     id_loop

        ret


printf:
        ; args: ax - number, bx - radix, bp - length (add leading zeros)
        push    dx
        push    cx
        xor     cx, cx

@@division_loop:
        xor     dx, dx
        div     bx
        push    dx
        inc     cx                      ; count number of characters in cx
        test    ax, ax
        jnz     @@division_loop

        mov     ah, 02h
        mov     dx, 30h

@@leading_zeros_loop:
        cmp     bp, cx
        jle     @@print_loop
        int     21h
        dec     bp
        jmp     @@leading_zeros_loop

@@print_loop:
        pop     dx
        cmp     dl, 10
        jb      @@decimal
        add     dl, 7                   ; add 7 for hex number
@@decimal:
        add     dl, 30h
        int     21h
        dec     cx
        jnz     @@print_loop

        pop     cx
        pop     dx
        ret


id_found_msg db " - ok", 0Ah, 24h

end start

        .model tiny
        locals
        .code
        org     100h
start:
        mov     cx, 0FFh

id_loop:
        xor     ax, ax
        mov     ah, cl
        push    cx

        int     2Fh

        test    ax, ax
        jz      id_loop_end

        lea     dx, [id_found_msg]
        mov     ah, 09h
        int     21h

id_loop_end:
        pop     cx
        dec     cx
        jnz     id_loop

        ret

id_found_msg db "resident found", 0Ah, 24h

end start

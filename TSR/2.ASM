    .model tiny
    locals
    .code
    org 100h

start:

        jmp     unload_vars

buffer db 20h, 00h, 00h, 01h, 00h, "hack3r", 69 dup(0)
buffer_length = $ - buffer

old_address_msg db "Old address:", 20h, 24h
new_address_msg db "New address:", 20h, 24h

unload_vars:
        mov     ah, 9h                  ; print old address of env vars
        lea     dx, [old_address_msg]
        int     21h

        mov     ax, cs:[2Ch]
        xor     bx, bx
        call    print_address

        mov     ah, 49h
        mov     es, cs:[2Ch]
        int     21h                     ; free memory at cs:[2Ch]
        jc      free_error

load_buffer:
        mov     ah, 48h
        mov     bx, 5
        int     21h                     ; allocate five paragraphs
        jc      alloc_error

        mov     es, ax                  ; offset of that paragraphs
        mov     cs:[2Ch], ax

        mov     cx, buffer_length       ; fill allocated paragraphs
        mov     si, offset buffer       ; (copy cx bytes
        mov     di, 0                   ; from ds:[si] to es:[di])
        rep     movsb

        mov     ah, 9h                  ; print new address of env vars
        lea     dx, [new_address_msg]
        int     21h

        mov     ax, es
        xor     bx, bx
        call    print_address

make_resident:
        mov     dx, 8                   ; reserve 8 * 16 bytes for PSP
        mov     ax, 3100h               ; make TSR (al - return code)
        int     21h

alloc_error:
        lea     dx, [alloc_error_msg]
        jmp     print
alloc_error_msg db "Error: cannot allocate memory", 24h

free_error:
        lea     dx, [free_error_msg]
        jmp     print
free_error_msg db "Error: cannot free memory", 24h

print:
        ; args: dx - address of string to print
        mov     ah, 9
        int     21h                     ; print string
        ret

print_address:
        ; args: ax - segment, bx - offset
        push    dx
        push    cx
        push    bx

        mov     bx, 10h
        mov     bp, 4h
        call    printf                  ; print segment address

        mov     ah, 02h
        mov     dx, 3Ah                 ; print ":"
        int     21h

        pop     ax                      ; offset in ax
        mov     bx, 10h
        mov     bp, 4h
        call    printf                  ; print offset address

        mov     ah, 02h
        mov     dx, 0Ah                 ; print "\n"
        int     21h

        pop     cx
        pop     dx
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

end start

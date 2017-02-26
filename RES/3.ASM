        .model tiny
        locals
        .code

use_27h_flag = 3732h
use_21h_flag = 3132h

        org     100h
start:

        jmp     validate_args

address_msg db "Address of environment variables:", 20h, 24h

validate_args:
        mov     ax, cs:[80h]
        test    al, al
        jz      no_args_error
        cmp     al, 3
        jne     unknown_args_error
        mov     ax, cs:[82h]
        cmp     ax, use_27h_flag
        je      print_vars_addr
        cmp     ax, use_21h_flag
        jne     unknown_args_error

print_vars_addr:
        mov     ah, 9h
        lea     dx, [address_msg]
        int     21h

        mov     ax, cs:[2Ch]
        xor     bx, bx
        call    print_segment_offset

select_resident_method:
        mov     ax, cs:[82h]
        cmp     ax, use_27h_flag
        je      make_resident_27h
        jmp     make_resident_21h

make_resident_21h:
        mov     dx, 16                  ; reserve 256 bytes for PSP
        mov     ax, 3100h               ; make TSR (al - return code)
        int     21h

make_resident_27h:
        lea     dx, [start]             ; offset of the end of resident code
        int     27h

unknown_args_error:
        lea     dx, [unknown_args_msg]
        jmp     print
unknown_args_msg db "Unknown argument: expected 21 or 27.", 24h

no_args_error:
        lea     dx, [no_args_msg]
        jmp     print
no_args_msg db "You have to choose how to make TSR: 21h or 27h.", 24h

print:
        ; args: dx - address of string to print
        mov     ah, 9
        int     21h                     ; print string
        ret

print_segment_offset:
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

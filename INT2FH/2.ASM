        .model tiny
        locals

; ## Constants ################################################################

multiplex_interrupt_no = 2Fh

; ## Code #####################################################################

        .code
        org     100h
start:
        jmp     tsr_init

; ## Data #####################################################################

old_handler_ptr dd ?

; ## Entry ####################################################################

tsr_entry:
        jmp     cs:[old_handler_ptr]

tsr_code_end:

; ## Init #####################################################################

tsr_init:

set_interrupt_vector:
        mov     ah, 35h
        mov     al, multiplex_interrupt_no
        int     21h                             ; get int vector in es:bx
        mov     word ptr cs:[old_handler_ptr], bx
        mov     word ptr cs:[old_handler_ptr+2], es
        mov     ax, es
        call    print_address
        lea     dx, [tsr_entry]
        mov     ah, 25h
        mov     al, multiplex_interrupt_no
        int     21h                             ; set int vector to ds:dx

install_tsr:
        lea     dx, [tsr_success_msg]
        mov     ah, 09h
        int     21h
        lea     dx, [tsr_code_end]
        int     27h

tsr_success_msg db "Resident successfully installed. Have a nice day :)", 24h

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

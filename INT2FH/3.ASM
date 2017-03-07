        .model tiny
        locals

; ## Constants ################################################################

multiplex_interrupt_no = 2Fh
my_function_no = 0C2h
my_subfunction_no = 04h

; ## Code #####################################################################

        .code
        org     100h
start:
        jmp     tsr_init

; ## Data #####################################################################

old_handler_ptr dd ?

; ## Entry ####################################################################

tsr_entry:
        cmp     ah, my_function_no      ; check, that this resident was called
        jne     tsr_refuse              ; call next handler in chain if not
        cmp     al, my_subfunction_no
        jne     tsr_refuse
        push    cx
        mov     cl, 8
        ror     dx, cl                  ; swap bytes in dx
        pop     cx
        iret

tsr_refuse:     ; call next handler in chain
        jmp     cs:[old_handler_ptr]

tsr_code_end:

; ## Init #####################################################################

tsr_init:
        call    find_installed_tsr
        test    ax, ax
        jnz     tsr_installed_error
        call    set_interrupt_vector
        call    install_tsr

tsr_installed_error:
        call    print_old_vector
        lea     dx, [tsr_installed_error_msg]
        jmp     tsr_error_finish
tsr_installed_error_msg db "Resident has already been installed, aborting :(", 24h

tsr_error_finish:
        mov     ah, 09h
        int     21h
        int     20h


find_installed_tsr:
        ; checks if tsr from this file was already installed earlier
        ; returns: ax = 1 if already installed, ax = 0 otherwise
        mov     ah, my_function_no
        mov     al, my_subfunction_no
        mov     dx, 0ACDCh
        int     2fh
        cmp     dx, 0DCACh
        je      @@find_success
        xor     ax, ax
        ret
@@find_success:
        mov     ax, 1
        ret


print_old_vector:
        mov     ah, 35h
        mov     al, multiplex_interrupt_no
        int     21h                             ; get int vector in es:bx
        mov     ah, 09h
        lea     dx, [old_msg]
        int     21h
        mov     ax, es
        call    print_address
        ret


set_interrupt_vector:
        mov     ah, 35h
        mov     al, multiplex_interrupt_no
        int     21h                             ; get int vector in es:bx
        mov     word ptr cs:[old_handler_ptr], bx
        mov     word ptr cs:[old_handler_ptr+2], es

        mov     ah, 09h
        lea     dx, [old_msg]
        int     21h

        mov     ax, es
        call    print_address

        mov     ah, 09h
        lea     dx, [new_msg]
        int     21h

        lea     dx, [tsr_entry]

        mov     ax, cs
        mov     bx, dx
        call    print_address

        mov     ah, 25h
        mov     al, multiplex_interrupt_no
        int     21h                             ; set int vector to ds:dx
        ret


old_msg db "Old vector: ", 24h
new_msg db "New vector: ", 24h


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

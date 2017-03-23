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

unique_token db "eb54674b-ddcd-5344-8ecd-422bc122450e", 00h    ; Version 5 UUID

old_handler_ptr dd ?
my_id db ?

; ## Entry ####################################################################

tsr_entry:
        cmp     ah, cs:[my_id]          ; check, that this resident was called
        jne     tsr_refuse              ; call next handler in chain if not
        push    ax
        mov     ax, cs
        mov     es, ax                  ; return pointer to unique token
        lea     di, [unique_token]      ; in es:di
        pop     ax
        mov     al, 0FFh                ; "Hey, I'm here!"
        iret

tsr_refuse:     ; call next handler in chain
        jmp     cs:[old_handler_ptr]

tsr_code_end:

; ## Init #####################################################################

tsr_init:
        call    select_free_id
        test    ax, ax
        jz      no_free_id_error
        mov     cs:[my_id], ah
        call    set_interrupt_vector
        call    install_tsr

tsr_installed_error:
        lea     dx, [tsr_installed_error_msg]
        jmp     tsr_error_finish
tsr_installed_error_msg db "Resident has already been installed, aborting :(", 24h

no_free_id_error:
        lea     dx, [no_free_id_error_msg]
        jmp     tsr_error_finish
no_free_id_error_msg db "No free ID was found for interrupt handler, aborting :(", 24h

tsr_error_finish:
        mov     ah, 09h
        int     21h
        int     20h


find_installed_tsr:
        ; checks if tsr from this file was already installed earlier
        ; returns: ax = ID if already installed, ax = 0 otherwise
        lea     si, [unique_token]
        mov     cx, 0FFh
@@check_loop:
        xor     ax, ax
        xor     di, di              ; expecting unique token address in di
        mov     ah, cl
        int     multiplex_interrupt_no
        test    di, di              ; if di is empty, skip cmpstr
        jz      @@check_loop_end
        mov     bx, ax              ; remember called ID
        call    strcmp              ; else need to compare tokens
        test    ax, ax
        jnz     @@check_loop_end    ; if tokens are not equal, continue
        mov     ax, bx              ; else return called ID
        ret
@@check_loop_end:
        dec     cx
        jnz     @@check_loop        ; while cx != 0
        xor     ax, ax              ; if token is not found, return 0
        ret


select_free_id:
        ; returns: ah = ID, if ID is found, ah = 0 otherwise
        mov     cx, 0FFh
@@select_id_loop:
        xor     ax, ax              ; loop over all IDs
        mov     ah, cl
        int     multiplex_interrupt_no
        test    al, al              ; if ok to install (al = 0), return this id
        jz      @@select_id_finish
        dec     cx
        jnz     @@select_id_loop
        xor     ax, ax              ; if not ok for all, return 0
@@select_id_finish:
        ret


set_interrupt_vector:
        mov     ah, 35h
        mov     al, multiplex_interrupt_no
        int     21h                             ; get int vector in es:bx
        mov     word ptr cs:[old_handler_ptr], bx
        mov     word ptr cs:[old_handler_ptr+2], es
        lea     dx, [tsr_entry]
        mov     ah, 25h
        mov     al, multiplex_interrupt_no
        int     21h                             ; set int vector to ds:dx
        ret


install_tsr:
        lea     dx, [tsr_success_msg]
        mov     ah, 09h
        int     21h
        lea     dx, [tsr_code_end]
        int     27h

tsr_success_msg db "Resident successfully installed. Have a nice day :)", 24h


strcmp:
        ; compare two zero terminated strings
        ; args: ds:si - first, es:di - second
        ; returns: ax = 0 if strings are equal, 1 otherwise
        push    si
        push    di
        push    cx
        call    strlen
@@strcmp_loop:
        cmpsb
        jne     @@strcmp_fail
        dec     cx
        jnz     @@strcmp_loop
        xor     ax, ax
        jmp     @@strcmp_ret
@@strcmp_fail:
        mov     ax, 1
@@strcmp_ret:
        pop     cx
        pop     di
        pop     si
        ret


strlen:
        ; calculate a length of the zero terminated string
        ; args: ds:si - string to calculate length
        ; returns: cx = length of the given string
        push    ax
        push    si              ; do not waste address in si
        xor     cx, cx
@@strlen_loop:
        lodsw
        test    al, al
        jz      @@strlen_finish
        inc     cx
        test    ah, ah
        jz      @@strlen_finish
        inc     cx
        jmp     @@strlen_loop
@@strlen_finish:
        pop     si
        pop     ax
        ret

end start

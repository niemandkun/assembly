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

end start

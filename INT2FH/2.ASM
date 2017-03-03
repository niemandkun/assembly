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
        xor     bx, bx
        mov     es, bx
        mov     bx, multiplex_interrupt_no
        shl     bx, 1
        shl     bx, 1                           ; es:bx - address of old vector
        mov     dx, es:[bx]
        mov     word ptr cs:[old_handler_ptr], dx
        lea     dx, [tsr_entry]
        mov     word ptr es:[bx], dx
        add     bx, 2
        mov     dx, es:[bx]
        mov     word ptr cs:[old_handler_ptr+2], dx
        mov     es:[bx], cs

install_tsr:
        lea     dx, [tsr_success_msg]
        mov     ah, 09h
        int     21h
        lea     dx, [tsr_code_end]
        int     27h

tsr_success_msg db "Resident successfully installed. Have a nice day :)", 24h

end start

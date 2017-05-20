        model   small
        locals

.stack

include com.asm
include string.asm
include print.asm
include args.asm
include ringbuf.asm
include inter.asm

text segment
        assume  cs:text, ds:text, es:text

handler:        ; offsets of handlers for each command
        dw      com_exit,   offset exit
        dw      com_up,     offset key_up
        dw      com_right,  offset key_right
        dw      com_left,   offset key_left
        dw      com_down,   offset key_down
        dw      com_tick,   offset on_tick
        dw      0FFFFh

start:
        call    parse_args

        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        call    setup_vector

@@1:
        hlt
        call    ring_buffer_read
        jc      @@1
        mov     si, offset handler
        xor     ah, ah
        mov     bx, ax
@@2:
        lodsw
        cmp     ax, 0FFFFh
        jz      @@1
        cmp     ax, bx
        jz      @@3
        add     si, 2
        jmp     @@2
@@3:
        lodsw
        call    ax
        jmp     @@1

exit proc near
        call    restore_vector
        mov     ah, 4ch
        int     21h
exit endp

on_tick proc near
        push    ax
        call    print_word
        pop     ax
        ret
on_tick endp

key_up proc near
        print
        ret
key_up endp

key_down proc near
        print
        ret
key_down endp

key_left proc near
        print
        ret
key_left endp

key_right proc near
        print
        ret
key_right endp

text ends

end start

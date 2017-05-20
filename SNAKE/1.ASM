        model   small
        locals

.stack

include com.asm
include string.asm
include print.asm
include args.asm
include ringbuf.asm
include inter.asm
include sound.asm
include zelda.asm

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
        call    start_player

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


;       handlers:

exit:
        call    stop_player
        call    restore_vector
        mov     ah, 4ch
        int     21h

on_tick:
        call    update_player
        ret

key_up:
        print
        ret

key_down:
        print
        ret

key_left:
        print
        ret

key_right:
        print
        ret

text ends

end start

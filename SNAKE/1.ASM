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
include model.asm
include graphics.asm
include random.asm

text segment
        assume  cs:text, ds:text, es:text

state_game:     ; offsets of handlers for each command
        dw      com_exit,   offset pause
        dw      com_up,     offset key_up
        dw      com_right,  offset key_right
        dw      com_left,   offset key_left
        dw      com_down,   offset key_down
        dw      com_tick,   offset game_tick
        dw      com_faster, offset speed_up
        dw      com_slower, offset speed_down
        dw      0FFFFh

state_pause:
        dw      com_exit,   offset gameover
        dw      com_tick,   offset menu_tick
        dw      com_start,  offset continue
        dw      0FFFFh

state_gameover:
        dw      com_exit,   offset exit
        dw      com_tick,   offset menu_tick
        dw      0FFFFh

state   dw      offset state_pause

start:
        call    parse_args

        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        call    setup_vector
        call    init_random
        call    init_model
        call    enable_graphics
        call    setup_sys_timer
        call    start_music

@@1:
        hlt
        call    ring_buffer_read
        jc      @@1
        mov     si, state
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
        call    stop_music
        call    reset_sys_timer
        call    restore_vector
        call    disable_graphics
        mov     ah, 4ch
        int     21h

ticks dw 0
update_interval dw 10h

pause:
        mov     state, offset state_pause
        call    clear_screen
        call    push_buffer
        ret

continue:
        call    stop_music
        mov     state, offset state_game
        call    clear_screen
        call    push_buffer
        ret

gameover:
        call    start_music
        mov     state, offset state_gameover
        call    clear_screen
        call    push_buffer
        ret

menu_tick:
        call    update_sound
        ret

game_tick:
        push    ax
        call    update_sound

        inc     ticks
        mov     ax, update_interval
        cmp     ticks, ax
        jl      @@finish

        call    update_model
        call    draw_scene
        mov     ticks, 0

@@finish:
        pop     ax
        ret

key_up:
        mov     velocity_x, 0
        mov     velocity_y, 1
        ret

key_down:
        mov     velocity_x, 0
        mov     velocity_y, -1
        ret

key_left:
        mov     velocity_x, -1
        mov     velocity_y, 0
        ret

key_right:
        mov     velocity_x, 1
        mov     velocity_y, 0
        ret

speed_up:
        dec     update_interval
        cmp     update_interval, 0
        jg      @@finish
        mov     update_interval, 1
@@finish:
        ret

speed_down:
        inc     update_interval
        cmp     update_interval, 10h
        jle     @@finish
        mov     update_interval, 10h
@@finish:
        ret

text ends

end start

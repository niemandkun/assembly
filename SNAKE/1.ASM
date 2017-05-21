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
include bitmaps.asm

text segment
        assume  cs:text, ds:text, es:text

state_game:     ; offsets of handlers for each command
        dw      com_exit,       offset pause
        dw      com_up,         offset key_up
        dw      com_right,      offset key_right
        dw      com_left,       offset key_left
        dw      com_down,       offset key_down
        dw      com_tick,       offset game_tick
        dw      com_faster,     offset speed_up
        dw      com_slower,     offset speed_down
        dw      com_sound,      offset on_sound
        dw      com_gameover,   offset gameover
        dw      0FFFFh

state_pause:
        dw      com_exit,       offset gameover
        dw      com_tick,       offset menu_tick
        dw      com_start,      offset continue
        dw      0FFFFh

state_gameover:
        dw      com_exit,       offset exit
        dw      com_tick,       offset menu_tick
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

logic_ticks dw 0
fixed_ticks dw 0

fixed_upd = 10h
logic_upd dw fixed_upd

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
        mov     logic_ticks, 0
        mov     fixed_ticks, 0
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
        cmp     logic_ticks, 0
        jge     @@fixed_update
        mov     ax, logic_upd
        mov     logic_ticks, ax
        call    update_model
        call    draw_scene
@@fixed_update:
        cmp     fixed_ticks, 0
        jge     @@finish
        mov     fixed_ticks, fixed_upd
        mov     ax, 6000h
        call    play_short_sound
@@finish:
        dec     logic_ticks
        dec     fixed_ticks
        pop     ax
        ret

on_sound:
        push    ax
        mov     ax, 2000h
        call    play_short_sound
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
        dec     logic_upd
        cmp     logic_upd, 0
        jg      @@finish
        mov     logic_upd, 1
@@finish:
        ret

speed_down:
        inc     logic_upd
        cmp     logic_upd, 10h
        jle     @@finish
        mov     logic_upd, 10h
@@finish:
        ret

text ends

end start

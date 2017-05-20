text segment

sound_on proc near
        in      al, 61h
        or      al, 00000011b
        out     61h, al
        ret
sound_on endp


sound_off proc near
        in      al, 61h
        and     al, 11111100b
        out     61h, al
        ret
sound_off endp


setup_sys_timer proc near
        mov     ax, 4800h
        call    set_sys_timer_freq
        ret
setup_sys_timer endp


reset_sys_timer proc near
        xor     ax, ax
        call    set_sys_timer_freq
        ret
reset_sys_timer endp


set_sys_timer_freq proc near
        push    bx
        mov     bx, ax

        cli
        mov     al, 00110100b
        out     43h, al

        mov     ax, bx
        out     40h, al
        mov     al, ah
        out     40h, al
        sti

        pop     bx
        ret
set_sys_timer_freq endp


play_note proc near

        ; args:
        ;       ah - scancode
        ; ret:
        ;       none

        push    ax
        push    bx
        push    si

        mov     bx, ax
        xor     bh, bh
        lea     si, [scale]

@@search_cycle:
        lodsw
        cmp     ax, 0FFh
        je      @@finish
        cmp     ax, bx
        je      @@key_found
        add     si, 2
        jmp     @@search_cycle

@@key_found:
        lodsw
        call    set_sound_freq
        call    sound_on

@@finish:
        pop     si
        pop     bx
        pop     ax
        ret

play_note endp


set_sound_freq proc near

        ; args:
        ;       ax - sound frequency
        ; ret:
        ;       none
        push    bx
        mov     bx, ax

        mov     al, 10110110b
        out     43h, al

        mov     ax, bx

        out     42h, al
        mov     al, ah
        out     42h, al

        pop     bx
        ret

set_sound_freq endp


ticks dw 0
note dw 0
duration dw 0


start_player proc c near uses ax
        xor     ax, ax
        call    set_sound_freq
        call    setup_sys_timer
        call    sound_on
        mov     note, offset zelda
        ret
start_player endp


update_player proc c near uses ax bx
        mov     ax, ticks
        mov     bx, duration
        cmp     ax, bx
        jge     @@play_next_note

        add     ax, 24
        mov     ticks, ax

        cmp     ax, bx
        jge     @@mute_note

        jmp     @@finish

@@play_next_note:
        xor     ax, ax
        mov     ticks, ax

        call    next_note
        jmp     @@finish

@@mute_note:
        xor     ax, ax
        call    set_sound_freq

@@finish:
        ret
update_player endp


stop_player proc c near uses ax
        xor     ax, ax
        call    set_sound_freq
        call    reset_sys_timer
        call    sound_off
        ret
stop_player endp


next_note proc c near uses ax bx cx si ds

        mov     ax, zelda_segment
        mov     ds, ax

        mov     si, cs:note
        lodsw

        cmp     ax, 0ffffh
        je      @@player_restart

        mov     cs:duration, ax

        xor     ax, ax
        lodsb

        sub     ax, 60
        add     ax, 24
        mov     cx, 2
        shl     ax, cl
        add     ax, 2
        add     ax, offset scale
        mov     bx, ax
        mov     ax, cs:[bx]

        call    set_sound_freq

        mov     cs:note, si
        jmp     @@finish

@@player_restart:
        mov     cs:duration, 0
        mov     cs:note, offset zelda

@@finish:
        ret

next_note endp

scale:
        dw      02h,    18242
        dw      03h,    17218
        dw      04h,    16252
        dw      05h,    15340
        dw      06h,    14479
        dw      07h,    13666
        dw      08h,    12899
        dw      09h,    12175
        dw      0Ah,    11492
        dw      0Bh,    10847
        dw      0Ch,    10238
        dw      0Dh,    9663

        dw      10h,    9121
        dw      11h,    8609
        dw      12h,    8126
        dw      13h,    7670
        dw      14h,    7239
        dw      15h,    6833
        dw      16h,    6449
        dw      17h,    6087
        dw      18h,    5746
        dw      19h,    5423
        dw      1Ah,    5119
        dw      1Bh,    4831

        dw      1Eh,    4560
        dw      1Fh,    4304
        dw      20h,    4063
        dw      21h,    3835
        dw      22h,    3619
        dw      23h,    3416
        dw      24h,    3224
        dw      25h,    3043
        dw      26h,    2873
        dw      27h,    2711
        dw      28h,    2559
        dw      1Ch,    2415

        dw      2Ah,    2280
        dw      2Ch,    2152
        dw      2Dh,    2031
        dw      2Eh,    1917
        dw      2Fh,    1809
        dw      30h,    1708
        dw      31h,    1612
        dw      32h,    1521
        dw      33h,    1436
        dw      34h,    1355
        dw      35h,    1279
        dw      36h,    1207

        dw      0FFh


text ends
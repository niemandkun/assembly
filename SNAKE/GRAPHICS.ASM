segment buffer_segment

double_buffer   db  64000 dup(?)

buffer_segment ends


text segment
        assume  cs:text, ds:text, es:text

bios_rom_segment = 0040h

bios_video_mode = 0049h
bios_video_page = 0062h

old_page db ?
old_mode db ?


snake_color = 15h
head_color = 17h
field_color = 5Bh
apple_color = 02h


draw_snake:
        mov     [si].@draw_proc, 0
        mov     cl, snake_color
        call    fill_tile
        ret


draw_head:
        mov     [si].@draw_proc, offset draw_snake
        mov     cl, head_color
        call    fill_tile
        ret


draw_empty:
        mov     [si].@draw_proc, 0
        mov     cl, field_color
        call    fill_tile
        ret


draw_apple:
        mov     [si].@draw_proc, 0
        mov     cl, apple_color
        call    fill_tile
        ret


enable_graphics   proc
        push    es
        push    ax

        mov     ax, bios_rom_segment
        mov     es, ax

        mov     al, es:[bios_video_mode]
        mov     old_mode, al
        mov     al, es:[bios_video_page]
        mov     old_page, al

        mov     ax, 13h
        int     10h

        call    clear_screen

        pop     ax
        pop     es
        ret
enable_graphics   endp


disable_graphics   proc
        xor     ax, ax
        mov     al, old_mode
        int     10h
        mov     ah, 05h
        mov     al, old_page
        int     10h
        ret
disable_graphics   endp


draw_scene      proc
        call    draw_tiles
        call    push_buffer
        ret
draw_scene      endp


tile_width = 10
tile_height = 10

screen_width = 320
screen_height = 200


draw_tiles      proc c near uses ax bx cx si ds es
        push    ds
        push    es

        mov     ax, tiles
        mov     ds, ax

        mov     ax, buffer_segment
        mov     es, ax

        xor     si, si
        xor     ax, ax
        xor     bx, bx
@@cycle:
        call    draw_tile
        add     si, size_of_tile
        cmp     si, offset tiles_end_ex
        jge     @@finish

        add     ax, tile_width
        cmp     ax, screen_width
        jne     @@cycle

        xor     ax, ax
        add     bx, tile_height
        jmp     @@cycle

@@finish:
        pop     es
        pop     ds
        ret
draw_tiles      endp


draw_tile       proc c near uses cx
        ; args:
        ;       es - buffer segment
        ;       ax - most left column
        ;       bx - most upper row
        ;       ds:si - pointer to Tile
        ; ret:
        ;       none
        mov     cx, [si].@draw_proc
        test    cx, cx
        jz      @@finish
        call    cx
@@finish:
        ret
draw_tile       endp


fill_tile       proc c near uses ax bx dx si di
        ; args:
        ;       ax - column
        ;       bx - row
        ;       cl - color
        ; ret:
        ;       none

        ; compare colors
        ; if colors match, nothing to do
        push    cx
        call    get_pixel
        mov     dx, cx
        pop     cx
        cmp     cl, dl
        je      @@finish

        mov     di, tile_height
        dec     di
@@cycle_y:
        mov     si, tile_width
        dec     si
@@cycle_x:
        add     ax, si
        add     bx, di
        call    set_pixel
        sub     bx, di
        sub     ax, si

        dec     si
        jge     @@cycle_x
        dec     di
        jge     @@cycle_y

@@finish:
        ret
fill_tile       endp


clear_screen    proc
        push    es

        mov     ax, buffer_segment
        mov     es, ax
        lea     di, [double_buffer]
        xor     di, di
        mov     ah, field_color
        mov     al, field_color
        mov     cx, 32000
        rep     stosw

        pop     es
        ret
clear_screen    endp


set_pixel       proc c uses ax bx dx es
        ; args:
        ;       ax - column
        ;       bx - row
        ;       cl - color
        ; ret:
        ;       none
        xchg    ax, bx
        mov     dx, 320
        mul     dx
        add     bx, ax
        add     bx, offset double_buffer

        mov     ax, buffer_segment
        mov     es, ax
        mov     byte ptr es:[bx], cl

        ret
set_pixel       endp


get_pixel       proc c uses ax bx dx es
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       cl - color
        xchg    ax, bx
        mov     dx, 320
        mul     dx
        add     bx, ax
        add     bx, offset double_buffer

        mov     ax, buffer_segment
        mov     es, ax
        mov     cl, byte ptr es:[bx]

        ret
get_pixel       endp


push_buffer     proc
        push    es
        push    ds
        mov     ax, 0a000h
        mov     es, ax

        mov     ax, buffer_segment
        mov     ds, ax

        mov     si, offset double_buffer
        xor     di, di
        mov     cx, 32000
        rep     movsw

        pop     ds
        pop     es
        ret
push_buffer     endp

text ends

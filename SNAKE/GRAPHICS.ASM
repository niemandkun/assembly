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
        call    clear_screen
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

        mov     cx, 0002h      ; color

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


draw_tile       proc
        ; args:
        ;       es - buffer segment
        ;       ax - most left column
        ;       bx - most upper row
        ;       ds:si - pointer to Tile
        ; ret:
        ;       none

        ; TODO
        call    set_pixel

        ret
draw_tile       endp


clear_screen    proc
        push    es

        mov     ax, buffer_segment
        mov     es, ax
        lea     di, [double_buffer]
        xor     di, di
        xor     ax, ax
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

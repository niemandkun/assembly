segment buffer_segment

double_buffer   db  64000 dup(?)

buffer_segment ends


text segment

draw_scene      proc
        call    clear_screen
        ; TODO
        call    push_buffer
        ret
draw_scene      endp


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

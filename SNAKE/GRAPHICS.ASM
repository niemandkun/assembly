segment buffer_segment

double_buffer   db  64000 dup(?)

buffer_segment ends


text segment

draw_scene      proc
        call    clear_screen
        call    draw_frame
        call    draw_circle
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


draw_frame      proc c uses ax bx cx dx
        mov     cl, frame_color

        mov     ax, frame_left
@@cycle1:
        mov     bx, frame_top
        call    set_pixel
        mov     bx, frame_bottom
        call    set_pixel
        inc     ax
        cmp     ax, frame_right
        jne     @@cycle1

        mov     bx, frame_top
@@cycle2:
        mov     ax, frame_left
        call    set_pixel
        mov     ax, frame_right
        call    set_pixel
        inc     bx
        cmp     bx, frame_bottom
        jne     @@cycle2

        ret
draw_frame       endp


draw_circle     proc c uses ax bx cx si di
        finit
        fild    circle_radius
        fmul    st(0), st(0)

        mov     si, circle_radius

@@cycle1:
        push    si
        mov     bx, sp
        fild    word ptr ss:[bx]
        fmul    st(0), st(0)
        fsubr   st(0), st(1)
        fsqrt
        frndint
        fistp   word ptr ss:[bx]
        pop     di

        mov     cl, circle_color
        mov     bx, di
        add     bx, circle_y
        neg     di
        add     di, circle_y

@@cycle2:
        mov     ax, si
        add     ax, circle_x
        call    set_pixel

        mov     ax, si
        neg     ax
        add     ax, circle_x
        call    set_pixel

        dec     bx
        cmp     bx, di
        jge     @@cycle2

        dec     si
        jge     @@cycle1

        ret
draw_circle     endp



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

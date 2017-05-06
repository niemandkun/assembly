text segment

color:
circle_color    db      01h
frame_color     db      0eh

frame_top       dw      20
frame_bottom    dw      100

frame_left      dw      20
frame_right     dw      200

circle_x        dw      20
circle_y        dw      20
circle_radius   dw      10

screen_width    dw      319
screen_height   dw      199

move_frame      proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       none
        call    clamp_by_scr
        call    clamp_frame

        add     frame_left, ax
        add     frame_right, ax

        add     frame_top, bx
        add     frame_bottom, bx

        add     circle_x, ax
        add     circle_y, bx

        ret
move_frame      endp


clamp_frame     proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       none
        push    dx
        add     ax, frame_left
        add     bx, frame_top

        push    ax
        ; now vertical delta in bx
        xor     ax, ax
        mov     cx, screen_height
        sub     cx, frame_bottom
        add     cx, frame_top
        call    clamp

        ; save clamped vertical delta in dx
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx
        xor     ax, ax
        mov     cx, screen_width
        sub     cx, frame_right
        add     cx, frame_left
        call    clamp
        ; now clamped horizontal delta in ax

        mov     bx, dx

        sub     ax, frame_left
        sub     bx, frame_top

        pop     dx
        ret
clamp_frame     endp


move_circle     proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       none
        push    dx
        call    clamp_by_scr
        call    clamp_by_frame

@@cmp_x:
        mov     dx, circle_y
        cmp     dx, frame_top
        je      @@move_x
        cmp     dx, frame_bottom
        je      @@move_x

@@cmp_y:
        mov     dx, circle_x
        cmp     dx, frame_left
        je      @@move_y
        cmp     dx, frame_right
        je      @@move_y

        jmp     @@finish

@@move_x:
        test    ax, ax
        jz      @@cmp_y

@@do_move_x:
        add     circle_x, ax
        jmp     @@finish

@@move_y:
        add     circle_y, bx

@@finish:
        pop     dx
        ret
move_circle     endp


clamp_by_scr    proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       ax - maximal allowed horizontal delta
        ;       bx - maximal allowed vertical delta
        push    dx
        push    cx

        add     ax, circle_x
        add     bx, circle_y
        push    ax

        ; have vertical delta in bx
        mov     ax, circle_radius
        mov     cx, screen_height
        sub     cx, ax
        ; after call ax = vertical delta
        call    clamp

        ; saving vertical delta in dx:
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx

        mov     ax, circle_radius
        mov     cx, screen_width
        sub     cx, ax
        ; after call ax = horizontal delta
        call    clamp

        ; remember, that dx = vertical delta
        mov     bx, dx

        sub     ax, circle_x
        sub     bx, circle_y

        pop     cx
        pop     dx
        ret
clamp_by_scr    endp


clamp_by_frame  proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       ax - maximal allowed horizontal delta
        ;       bx - maximal allowed vertical delta
        push    dx
        push    cx

        add     ax, circle_x
        add     bx, circle_y
        push    ax

        ; have vertical delta in bx
        mov     ax, frame_top
        mov     cx, frame_bottom
        ; after call ax = vertical delta
        call    clamp

        ; saving vertical delta in dx:
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx

        mov     ax, frame_left
        mov     cx, frame_right
        ; after call ax = horizontal delta
        call    clamp

        ; remember, that dx = vertical delta
        mov     bx, dx

        sub     ax, circle_x
        sub     bx, circle_y

        pop     cx
        pop     dx
        ret
clamp_by_frame  endp


clamp           proc
        ; args:
        ;       ax, bx, cx - numbers
        ; ret:
        ;       bx, if ax <= bx <= cx
        ;       ax, if bx < ax
        ;       cx, if cx < bx
        call    max
        mov     bx, cx
        call    min
        ret
clamp           endp


min             proc
        ; args:
        ;       ax - first number
        ;       bx - second number
        ; ret:
        ;       ax - minimum of two numbers
        cmp     ax, bx
        jl      @@finish
        xchg    ax, bx
@@finish:
        ret
min             endp


max             proc
        ; args:
        ;       ax - first number
        ;       bx - second number
        ; ret:
        ;       ax - maximum of two numbers
        cmp     ax, bx
        jg      @@finish
        xchg    ax, bx
@@finish:
        ret
max             endp

text ends

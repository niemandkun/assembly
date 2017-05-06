        model   small
        locals

.stack

text segment
        assume  cs:text, ds:text, es:text

start:
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        ; set 10h video mode
        mov     ax, 13h
        int     10h

        ; reset mouse state
        xor     ax, ax
        int     33h

        ; show mouse pointer
        ;mov     ax, 1
        ;int     33h

        ; draw initial scene
        call    clear_screen
        call    draw_frame
        call    draw_circle
        call    push_buffer

        ; set user-defined callback for mouse events
        ; CX = user interrupt mask

        ; |F-5|4|3|2|1|0| user interrupt mask in CX
        ;   |  | | | | `--- cursor position changed
        ;   |  | | | `---- left button pressed
        ;   |  | | `----- left button released
        ;   |  | `------ right button pressed
        ;   |  `------- right button released
        ;   `--------- unused

        mov     cx, 01h
        lea     dx, [handle_mouse]
        mov     ax, 0ch
        int     33h

        ; wait any key
        xor     ax, ax
        int     16h

        ; reset mouse again to delete callback
        xor     ax, ax
        int     33h

        ; reset video mode back to normal
        mov     ax, 03h
        int     10h

        ; exit
        mov     ah, 4ch
        int     21h

handle_mouse    proc
        ; AX = condition mask causing call
        ; CX = horizontal cursor position
        ; DX = vertical cursor position
        ; DI = horizontal counts
        ; SI = vertical counts
        ; DS = mouse driver data segment
        ; BX = button state:
        ;
        ;    |F-2|1|0|
        ;      |  | `--- left button (1 = pressed)
        ;      |  `---- right button (1 = pressed)
        ;      `------ unused
        push    bx

        mov     ax, cx
        sub     ax, cs:old_pos_x
        mov     cs:old_pos_x, cx

        mov     bx, dx
        sub     bx, cs:old_pos_y
        mov     cs:old_pos_y, dx

        ;mov     dx, word ptr cs:color
        ;xor     cx, cx
        ;mov     word ptr cs:color, cx

        ;call    draw_frame
        ;call    draw_circle

        pop     cx

        test    cx, 1
        jnz     @@move_frame

        call    move_circle
        jmp     @@finish

@@move_frame:
        call    move_frame

@@finish:
        ;mov     word ptr cs:color, dx
        call    clear_screen
        call    draw_frame
        call    draw_circle
        call    push_buffer

        retf
handle_mouse    endp

color:
circle_color    db      01h
frame_color     db      0eh

old_pos_x       dw      0
old_pos_y       dw      0

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

        add     cs:frame_left, ax
        add     cs:frame_right, ax

        add     cs:frame_top, bx
        add     cs:frame_bottom, bx

        add     cs:circle_x, ax
        add     cs:circle_y, bx

        ret
move_frame      endp


clamp_frame     proc
        ; args:
        ;       ax - horizontal delta
        ;       bx - vertical delta
        ; ret:
        ;       none
        push    dx
        add     ax, cs:frame_left
        add     bx, cs:frame_top

        push    ax
        ; now vertical delta in bx
        xor     ax, ax
        mov     cx, cs:screen_height
        sub     cx, cs:frame_bottom
        add     cx, cs:frame_top
        call    clamp

        ; save clamped vertical delta in dx
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx
        xor     ax, ax
        mov     cx, cs:screen_width
        sub     cx, cs:frame_right
        add     cx, cs:frame_left
        call    clamp
        ; now clamped horizontal delta in ax

        mov     bx, dx

        sub     ax, cs:frame_left
        sub     bx, cs:frame_top

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
        mov     dx, cs:circle_y
        cmp     dx, cs:frame_top
        je      @@move_x
        cmp     dx, cs:frame_bottom
        je      @@move_x

@@cmp_y:
        mov     dx, cs:circle_x
        cmp     dx, cs:frame_left
        je      @@move_y
        cmp     dx, cs:frame_right
        je      @@move_y

        jmp     @@finish

@@move_x:
        test    ax, ax
        jz      @@cmp_y

@@do_move_x:
        add     cs:circle_x, ax
        jmp     @@finish

@@move_y:
        add     cs:circle_y, bx

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

        add     ax, cs:circle_x
        add     bx, cs:circle_y
        push    ax

        ; have vertical delta in bx
        mov     ax, cs:circle_radius
        mov     cx, cs:screen_height
        sub     cx, ax
        ; after call ax = vertical delta
        call    clamp

        ; saving vertical delta in dx:
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx

        mov     ax, cs:circle_radius
        mov     cx, cs:screen_width
        sub     cx, ax
        ; after call ax = horizontal delta
        call    clamp

        ; remember, that dx = vertical delta
        mov     bx, dx

        sub     ax, cs:circle_x
        sub     bx, cs:circle_y

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

        add     ax, cs:circle_x
        add     bx, cs:circle_y
        push    ax

        ; have vertical delta in bx
        mov     ax, cs:frame_top
        mov     cx, cs:frame_bottom
        ; after call ax = vertical delta
        call    clamp

        ; saving vertical delta in dx:
        mov     dx, ax

        pop     bx
        ; now horizontal delta in bx

        mov     ax, cs:frame_left
        mov     cx, cs:frame_right
        ; after call ax = horizontal delta
        call    clamp

        ; remember, that dx = vertical delta
        mov     bx, dx

        sub     ax, cs:circle_x
        sub     bx, cs:circle_y

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

include print.asm
include graphics.asm

text ends

segment buffer_segment
double_buffer   db  64000 dup(?)
buffer_segment ends

end start

tiles segment

Tile struc
    @snake_next dw 0
    @bonus dw 0
    @wall dw 0
Tile ends

size_of_tile = 6

Tile 640 dup(?)

tiles_end_ex = $

field_width = 32
field_height = 20

tiles ends


text segment
        assume  cs:text

velocity_x dw 1
velocity_y dw 0

snake_head dw offset tiles + (size_of_tile * 100)

update_model    proc c near uses ax bx ds
        mov     ax, velocity_y
        mov     bx, size_of_tile
        mul     bx
        mov     bx, field_width
        mul     bx

        add     snake_head, ax

        mov     ax, velocity_x
        mov     bx, size_of_tile
        mul     bx

        add     snake_head, ax

        mov     bx, snake_head

        cmp     bx, 0
        jl      @@finish

        cmp     bx, offset tiles_end_ex
        jg      @@finish

        mov     ax, tiles
        mov     ds, ax

        mov     [bx].@snake_next, 1

@@finish:
        ret
update_model    endp


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

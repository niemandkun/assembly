tiles segment

Tile struc
    @snake_next dw ?
    @bonus dw ?
    @wall dw ?
Tile ends

size_of_tile = 6

Tile 640 dup(?)

tiles_end_ex = $

tiles ends


text segment
        assume  cs:text

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

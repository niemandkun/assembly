tiles segment

Tile struc
    @snake_next dw 0
    @bonus dw 0
    @wall dw 0
    @draw_proc dw 0
Tile ends

size_of_tile = 8

Tile 640 dup(?)

tiles_end_ex = $

field_width = 32
field_height = 20

head_of_snake = 0ffffh

tiles ends


text segment
        assume  cs:text

velocity_x dw 1
velocity_y dw 0

delta_length dw 5
snake_length dw 0

snake_start_x = 15
snake_start_y = 15

snake_head_x dw snake_start_x
snake_head_y dw snake_start_y

snake_tail_ptr dw (snake_start_x + snake_start_y * field_width) * size_of_tile


update_model    proc c near uses ax bx es
        mov     ax, tiles
        mov     es, ax

        call    move_head
        call    move_tail
        ret
update_model    endp


move_head       proc c near uses ax bx
        mov     ax, snake_head_x
        mov     bx, snake_head_y

        mov     cx, ax  ; CX = old x
        mov     dx, bx  ; DX = old y

        add     ax, velocity_x
        add     bx, velocity_y

        call    torus_cycle

        mov     snake_head_x, ax
        mov     snake_head_y, bx

        call    get_tile_ptr
        ; got ptr to new snake head in BX

        mov     es:[bx].@snake_next, head_of_snake
        mov     es:[bx].@draw_proc, offset draw_head

        xchg    ax, cx
        xchg    bx, dx
        ; ptr to new head is in DX now

        call    get_tile_ptr
        ; got ptr to old snake head in BX

        mov     es:[bx].@snake_next, dx
        mov     es:[bx].@draw_proc, offset draw_snake
        ret
move_head       endp


move_tail       proc c near uses ax bx
        mov     ax, delta_length
        test    ax, ax
        jz      @@do_move_tail

        dec     ax
        mov     delta_length, ax
        inc     snake_length
        jmp     @@finish

@@do_move_tail:
        mov     bx, snake_tail_ptr
        mov     ax, es:[bx].@snake_next
        mov     snake_tail_ptr, ax
        mov     es:[bx].@snake_next, 0
        mov     es:[bx].@draw_proc, offset draw_empty

@@finish:
        ret
move_tail       endp


get_tile_ptr    proc near
        ; args:
        ;       ax - column
        ;       bx - row
        ; ret:
        ;       bx - ptr to tile struct
        push    cx
        push    dx

        xchg    ax, bx
        xor     dx, dx

        mov     cx, field_width
        mul     cx

        add     ax, bx

        mov     cx, size_of_tile
        mul     cx

        xchg    ax, bx

        pop     dx
        pop     cx
        ret
get_tile_ptr    endp


torus_cycle     proc
        ; args:
        ;       AX - column
        ;       BX - row
        ; ret:
        ;       coordinates on torus:
        ;       0 <= AX < field_width
        ;       0 <= BX < field_height
@@ax_under:
        cmp     ax, 0
        jge     @@ax_over
        add     ax, field_width
        jmp     @@ax_under

@@ax_over:
        cmp     ax, field_width
        jl      @@bx_under
        sub     ax, field_width
        jmp     @@ax_over

@@bx_under:
        cmp     bx, 0
        jge     @@bx_over
        add     bx, field_height
        jmp     @@bx_under

@@bx_over:
        cmp     bx, field_height
        jl      @@finish
        sub     bx, field_height
        jmp     @@bx_over

@@finish:
        ret
torus_cycle     endp


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

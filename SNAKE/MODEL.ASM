tiles segment

size_of_tile = 8

Tile struc
    @snake dw 0
    @bonus dw 0
    @wall dw 0
    @draw_proc dw 0
Tile ends

Tile 640 dup(?)
tiles_end_ex = $

snake   dw  640 dup(?)
snake_end_ex = $

tiles ends


field_width = 32
field_height = 20

head_of_snake = 0ffffh


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

snake_head_ptr dw offset snake
snake_tail_ptr dw offset snake

items_count dw 10


init_model      proc c near uses ax bx cx dx es
        mov     ax, tiles
        mov     es, ax

        ; set pointer to tile with snake head in snake array
        mov     ax, snake_head_x
        mov     bx, snake_head_y

        call    get_tile_ptr
        mov     dx, bx
        ; pointer in DX now

        mov     bx, snake_head_ptr
        mov     es:[bx], dx

        ; spawn initial items
        mov     cx, items_count
@@cycle:
        mov     ax, field_height
        call    random_get
        mov     bx, ax          ; row in BX
        mov     ax, field_width
        call    random_get      ; column in AX

        call    get_tile_ptr
        mov     es:[bx].@bonus, 1
        mov     es:[bx].@draw_proc, offset draw_apple

        dec     cx
        jnz     @@cycle

        ret
init_model      endp


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

        add     ax, velocity_x
        add     bx, velocity_y

        call    torus_cycle

        mov     snake_head_x, ax
        mov     snake_head_y, bx

        call    get_tile_ptr
        ; got ptr to new snake head in BX

        mov     es:[bx].@draw_proc, offset draw_head
        inc     es:[bx].@snake

        mov     dx, bx
        ; ptr to new head is in DX now

        ; create pointer to new head
        mov     bx, snake_head_ptr
        add     bx, 2
        cmp     bx, offset snake_end_ex
        jne     @@write_head_ptr

        mov     bx, offset snake

@@write_head_ptr:
        ; write pointer to new head into the new cell
        mov     es:[bx], dx
        mov     snake_head_ptr, bx

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
        mov     bx, es:[bx]
        ; pointer to tile in BX

        dec     es:[bx].@snake
        jne     @@is_not_empty

        mov     es:[bx].@draw_proc, offset draw_empty

@@is_not_empty:
        mov     bx, snake_tail_ptr
        add     bx, 2
        cmp     bx, offset snake_end_ex
        jne     @@write_tail_ptr

        mov     bx, offset snake

@@write_tail_ptr:
        mov     snake_tail_ptr, bx

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

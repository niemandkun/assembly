model tiny
locals
.386

include vga.asm

.data

func_step       dq  0.02
func_start      dq  -20.0

x_scale         dq  8.0
y_scale         dq  50.0

func_res        dw  0

axes_color = 05h
plot_color = 03h
dashes_width = 4

.code
    org     100h

start:
    init_vga_mode
    mov     cl, axes_color
    call    draw_ox
    call    draw_oy
    call    draw_ox_dashes
    call    draw_oy_dashes
    mov     cl, plot_color
    call    draw_plot
    call    reset_cursor
    ret

put_pixel:
    ; put pixel on the screen
    ; args:
    ; ax: y coordinate, bx: x coordinate, cl: pixel color
    test    ax, ax
    jl      @@1                 ; check that the pixel is inside
    test    bx, bx              ; of the screen borders
    jl      @@1
    cmp     ax, vga_height
    jge     @@1
    cmp     bx, vga_width
    jge     @@1

    mov     dx, vga_width       ; calculate address in a memory
    mul     dx
    add     bx, ax
    mov     [es:bx], cl         ; set value in the video memory
@@1:
    ret

reset_cursor:
    mov     dh, 0               ; set cursor to upper left corner
    mov     dl, 0
    call    set_cursor
    ret

set_cursor_vga:
    ; set cursor position in mode 13h
    ; ax: y coordinate, bx: x coordinate
    push    cx
    push    dx

    xor     dx, dx              ; calculate row
    mov     cx, char_height
    div     cx
    xchg    bx, ax
    mov     bh, bl              ; store row in bh

    mov     cx, char_width      ; calculate column
    div     cx

    mov     bl, al              ; store column in bl
    mov     dx, bx              ; mov dl, bl; mov dh, bh
    call    set_cursor

    pop     dx
    pop     cx

    ret

set_cursor:
    ; set cursor position
    ; dh: row, dl: column
    mov     ah, 02h
    xor     bh, bh
    int     10h
    ret

put_char:
    ; put char on the screen
    ; ch: char, cl: color
    mov     ah, 0eh
    mov     al, ch
    mov     bl, cl
    int     10h
    ret

draw_ox:
    mov     di, vga_height / 2      ; y coordinate
    mov     si, vga_width - 1       ; x coordinate
@@1:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    dec     si                      ; cycle over all x coordinates
    jge     @@1

    mov     dl, 37                  ; print 'x' at 11 row, 37 column
    mov     dh, 11
    call    set_cursor
    mov     ch, 'x'
    call    put_char

    ret

draw_oy:
    mov     di, vga_height - 1      ; y coordinate
    mov     si, vga_width / 2       ; x coordinate
@@1:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    dec     di                      ; cycle over all y coordinates
    jge     @@1

    mov     dl, 21                  ; print 'y' at 1 row, 21 column
    mov     dh, 1
    call    set_cursor
    mov     ch, 'y'
    call    put_char

    ret

draw_oy_dashes:
    ;si: x, di: y

    ;; draw upper dashes
    mov     di, vga_height / 2 - 25         ; di - rows
    mov     ch, 1 + 30h                     ; si - columns
@@1:
    mov     si, (vga_width - dashes_width) / 2  ; si - const
@@2:
    mov     ax, di              ; while di > 0 draw dashes
    mov     bx, si
    call    put_pixel           ; while drawing dash
    inc     si                  ; iterate over x coordinate
    cmp     si, (vga_width + dashes_width) / 2
    jle     @@2

    mov     ax, di              ; create text under the dash
    mov     bx, si              ; ch - current number charcode
    sub     bx, 16
    call    set_cursor_vga
    call    put_char
    inc     ch

    sub     di, 25              ; iterate over rows (di)
    jg      @@1                 ; implicit compare di with zero

    ;; draw bottom dashes
    mov     di, vga_height / 2 + 25     ; same thing but now upside-down
    mov     ch, 1 + 30h                 ; iterate over rows
@@3:
    mov     si, (vga_width - dashes_width) / 2
@@4:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    inc     si
    cmp     si, (vga_width + dashes_width) / 2
    jle     @@4

    mov     ax, di          ; draw current character
    mov     bx, si
    add     bx, 16
    call    set_cursor_vga
    call    put_char
    inc     ch

    push    cx              ; remember current character
    mov     ax, di          ; because we wanna draw a minus sign
    mov     bx, si
    add     bx, 8
    mov     ch, '-'
    call    set_cursor_vga
    call    put_char
    pop     cx

    add     di, 25
    cmp     di, vga_height
    jl      @@3
    ret

draw_ox_dashes:
    ;si: x, di: y

    ;; draw right dashes
    mov     si, vga_width / 2 + 8*5     ; same thing again for Ox
    mov     ch, 1 + 30h                 ; iterate over columns
@@1:
    mov     di, (vga_height - dashes_width) / 2
@@2:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    inc     di
    cmp     di, (vga_height + dashes_width) / 2
    jle     @@2

    mov     ax, di          ; ax - row
    mov     bx, si          ; bx - column
    add     ax, 10
    call    set_cursor_vga
    call    put_char
    inc     ch

    add     si, 8*5
    cmp     si, vga_width
    jl      @@1

    ;; draw left dashes
    mov     si, vga_width / 2 - 8*5
    mov     ch, 1 + 30h
@@3:
    mov     di, (vga_height - dashes_width) / 2
@@4:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    inc     di
    cmp     di, (vga_height + dashes_width) / 2
    jle     @@4

    mov     ax, di
    mov     bx, si
    sub     ax, 10
    call    set_cursor_vga
    call    put_char
    inc     ch

    push    cx
    mov     ax, di
    mov     bx, si
    sub     ax, 10
    sub     bx, 8
    call    set_cursor_vga
    mov     ch, '-'
    call    put_char
    pop     cx

    sub     si, 8*5
    jg      @@3
    ret

draw_plot:
    finit

    ; in this procedure FPU stack is operating as follows:
    ;
    ; +---------------------+
    ; |       x_scale       | 4
    ; +---------------------+
    ; |       y_scale       | 3
    ; +---------------------+
    ; |      calc_step      | 2
    ; +---------------------+
    ; |         arg         | 1
    ; +---------------------+
    ; |         res         | 0
    ; +---------------------+
    ;
    ; Algorithm:
    ;
    ;   st4 := x_scale
    ;   st3 := y_scale
    ;   st2 := calc_step
    ;   st1 := arg
    ;   while is not calculated:
    ;       st0 := st1
    ;       st0 := sin(st0)
    ;       st0 /= st1
    ;       st0 *= y_scale
    ;       pop st0
    ;       st0 := arg
    ;       st0 *= x_scale
    ;       pop st0
    ;       st1 += calc_step

    fld     qword ptr [x_scale]
    fld     qword ptr [y_scale]
    fld     qword ptr [func_step]
    fld     qword ptr [func_start]
@@1:
    fld     st(0)
    fsin                        ; calculate actual function
    fdiv    st(0), st(1)
    ; pop result
    fmul    st(0), st(3)            ; apply vertical aspect ratio
    fistp   word ptr [func_res]
    mov     ax, word ptr [func_res]
    neg     ax
    ; pop arg
    fld     st(0)
    fmul    st(0), st(4)            ; apply horizontal aspect ratio
    fistp   word ptr [func_res]
    mov     bx, word ptr [func_res]
    add     ax, vga_height/2        ; shift to the center of the screen
    add     bx, vga_width/2
    mov     di, bx
    mov     cl, plot_color
    call    put_pixel
    fadd    st(0), st(1)            ; add calc_step to arg
    cmp     di, vga_width
    jbe     @@1
    ret

end start

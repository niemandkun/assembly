model tiny
locals
.386

include vga.asm

.data

func_step       dq  0.02
func_left       dq  -25.0
func_right      dq  25.0
func_top        dq  -1.5
func_bottom     dq  1.5
func_res        dw  0

viewport_width  dq  320.0
viewport_height dq  200.0

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

    mov     dx, vga_width
    mul     dx
    add     bx, ax
    mov     [es:bx], cl         ; set value in the video memory
@@1:
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
    ret

draw_oy_dashes:
    ;si: x, di: y
    mov     di, vga_height
@@1:
    mov     si, (vga_width - dashes_width) / 2
@@2:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    inc     si
    cmp     si, (vga_width + dashes_width) / 2
    jle     @@2
    sub     di, 20
    jg      @@1
    ret

draw_ox_dashes:
    ;si: x, di: y
    mov     si, vga_width
@@1:
    mov     di, (vga_height - dashes_width) / 2
@@2:
    mov     ax, di
    mov     bx, si
    call    put_pixel
    inc     di
    cmp     di, (vga_height + dashes_width) / 2
    jle     @@2
    sub     si, 20
    jg      @@1
    ret

draw_plot:
    finit

    ; in this procedure FPU stack is operating as follows:
    ;
    ; +-------------------+
    ; |   x_aspect_ratio  | 4
    ; +-------------------+
    ; |   y_aspect_ratio  | 3
    ; +-------------------+
    ; |     calc_step     | 2
    ; +-------------------+
    ; |        arg        | 1
    ; +-------------------+
    ; |        res        | 0
    ; +-------------------+
    ;
    ; Algorithm:
    ;   calculate aspect ratio on st3 and st4:
    ;       aspect := viewport / (func_max - func_min)
    ;   st2 := calc_step
    ;   st1 := first_arg
    ;   while is not calculated:
    ;       st0 := arg
    ;       st0 := sin(st0)
    ;       st0 /= arg
    ;       st0 *= y_aspect_ratio
    ;       pop st0
    ;       st0 := arg
    ;       st0 *= x_aspect_ratio
    ;       pop st0

    ; calculate horizontal (x) aspect ratio
    fld     qword ptr [viewport_width]
    fld     qword ptr [func_right]
    fld     qword ptr [func_left]
    fsubp
    fdivp
    ; calculate vertical (y) aspect ratio
    fld     qword ptr [viewport_height]
    fld     qword ptr [func_top]
    fld     qword ptr [func_bottom]
    fsubp
    fdivp
    ; push calculation step
    fld     qword ptr [func_step]
    ; push the most left argument of the function
    fld     qword ptr [func_left]
    ; TODO: calculate this number dynamically
    mov     cx, 2500
@@1:
    push    cx
    fld     st(0)
    fsin                        ; calculate actual function
    fdiv    st(0), st(1)
    ; pop result
    fmul    st(0), st(3)            ; apply vertical aspect ratio
    fistp   word ptr [func_res]
    mov     ax, word ptr [func_res]
    ; pop arg
    fld     st(0)
    fmul    st(0), st(4)            ; apply horizontal aspect ratio
    fistp   word ptr [func_res]
    mov     bx, word ptr [func_res]
    add     ax, vga_height/2        ; shift to the center of the screen
    add     bx, vga_width/2
    mov     cl, plot_color
    call    put_pixel
    fadd    st(0), st(1)            ; add calc_step to arg
    pop     cx
    dec     cx
    ja      @@1
    ret

end start

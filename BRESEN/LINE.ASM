model tiny
locals
.386

include vga.asm

.code
    org     100h

start:

    init_vga_mode

irp y1, 10,30,50,70,90,110,130,150,170,190
    mov     ax, 10
    mov     bx, 10
    mov     cx, y1
    mov     dx, 300
    call    line
endm

    gchar

    init_text_mode

    ret

line:
    ; ax - y0, bx - x0
    ; cx - y1, dx - x1
    ; uses si, di

    mov     si, dx
    sub     si, bx      ; si - deltax

    sub     cx, ax      ; cx - deltay

    mov     di, cx      ; di - error
    shr     di, 1
    sub     di, si      ; error = 2*deltay - deltax

cycle:
    push    ax
    push    bx
    push    dx

    ppixel  ax, bx, 03h

    pop     dx
    pop     bx
    pop     ax

    test    di, di      ; if error <= 0
    jle     no_error    ; goto no_error
                        ; else
error:
    inc     ax          ; y += 1
    sub     di, si      ; error -= deltax

no_error:
    add     di, cx      ; error += deltay

    inc     bx          ; x += 1
    cmp     bx, dx      ; if x <= x1
    jle     cycle       ; goto cycle

    ret

end start

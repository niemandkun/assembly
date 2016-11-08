printf macro msg
    mov     ah, 9
    mov     dx, offset msg
    int     21h
endm

sprintf macro msg
    local   m1
    local   m2

    jmp     m2
m1  db      msg, 0dh, 0ah, 24h
m2:
    printf  m1

endm

rpush macro x1, x2, x3
    push    &x1&x
    push    &x2&x
    push    &x3&x
endm

rpop macro x1, x2, x3
    pop     &x1&x
    pop     &x2&x
    pop     &x3&x
endm

superpush macro x
    irp xx, x
        push    xx
    endm
endm

supermul macro x
    if x eq 2
        shl     ax, 1
    elseif x eq 4
        shl     ax, 2
    elseif x eq 8
        shl     ax, 3
    else
        mov     bx, x
        mul     ax
    endif
endm

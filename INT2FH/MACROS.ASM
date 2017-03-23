conflicting macro args, handler
        xor     ax, ax
    irp xx, <args>
        mov     bx, [xx]
        mov     dx, bx
        shl     bx, 1
        add     bx, ax
        cmp     bx, 11b
        je      handler
        or      ax, dx
    endm
endm


requiring macro parent, args, handler
        local   m1
        mov     ax, [parent]
        test    ax, ax
        jz      m1
        xor     ax, ax
    irp xx, <args>
        or      ax, [xx]
    endm
        test    ax, ax
        jz      handler
m1:
endm

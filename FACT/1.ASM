        .model tiny
        .code
        org 100h
        locals
start:
        xor     cx, cx

@@1:
        push    cx
        mov     ax, cx
        call    factorial
        mov     bx, 10
        call    print
        pop     cx

        inc     cx
        cmp     cx, 10
        jne     @@1

        ret


factorial:
;       args:       ax - a number
;       uses:       ax, bx, dx, cx
;       returns:    dx:ax - factorial of the given number

        xchg    ax, cx      ; given number is a counter
        xor     dx, dx
        xor     bx, bx      ; bx - most sign path
        mov     ax, 1       ; ax - less sign part
@@cycle:
        test    cx, cx
        jz      @@exit

        xchg    ax, bx
        mul     cx          ; multipli bx
        xchg    ax, bx
        mul     cx          ; multiply ax
        add     bx, dx

        dec     cx
        jmp     @@cycle
@@exit:
        xchg    dx, bx
        ret


print:
;       args:       dx:ax - number to print
;                   bx - radix
;       uses:       ax, bx, cx, dx
;       returns:    nothing

        xor     cx, cx
@@1:
        div     bx
        push    dx
        inc     cx

        xor     dx, dx
        test    ax, ax
        jnz     @@1

        mov     ah, 02h
@@2:
        pop     dx
        cmp     dl, 10
        jb      @@3
        add     dl, 7       ; hack to print HEX digits
@@3:
        add     dl, 30h
        int     21h

        dec     cx
        test    cx, cx
        jnz     @@2

        mov     dl, 0Ah     ; print new line character
        int     21h

        ret

end start

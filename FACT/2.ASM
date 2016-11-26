        .model tiny
        .code
        org 100h
        locals
        .386
start:
        push    bp
        mov     bp, sp

        xor     cx, cx

@@1:
        push    cx
        push    cx

        call    factorial

        add     sp, 2

        push    10
        push    bx
        push    ax

        call    print

        add     sp, 6

        pop     cx
        inc     cx
        cmp     cx, 10
        jne     @@1

        pop     bp

        ret


factorial:
;       args:       WORD - a number
;       uses:       ax, bx, dx, cx
;       returns:    bx:ax - factorial of the given number
;                   bx - most significant part
;                   ax - less significant part

        push    bp
        mov     bp, sp

        mov     cx, [bp+4]  ; load argument into cx

        test    cx, cx
        jnz     @@1         ; if argument is zero

        xor     bx, bx
        mov     ax, 1       ; return 1
        jmp     @@2
@@1:
        push    cx          ; save register
        dec     cx

        push    cx          ; push argument
        call    factorial
        add     sp, 2       ; clear stack

        pop     cx          ; load saved register

        xchg    ax, bx
        mul     cx      ; multiply most sign part
        xchg    ax, bx
        mul     cx
        add     bx, dx
@@2:
        pop     bp

        ret


print:
;       args:       DWORD - number to print
;                   WORD  - radix
;       returns:    nothing

        push    bp
        mov     bp, sp

        mov     ax, [bp+4]
        mov     dx, [bp+6]
        mov     bx, [bp+8]

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

        pop     bp

        ret

end start

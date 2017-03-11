.model tiny
locals

; constants:

argcPtr = 80h
argvPtr = argcPtr + 1

.code
        org     100h

start:
        lea     ax, [lexemes]
        mov     ax, acceptableLexemesLength

        xor     dx, dx
        mov     dl, cs:[argcPtr]
        push    dx

        mov     dx, argvPtr
        push    dx

        call    parseArgs
        add     sp, 2 + 2

        int     20h


debugPrint proc c near uses

        mov     ax, [tokensCount]

        push    ax
        call    printWord

        mov     ax, newLine
        push    ax
        call    putChar
        add     sp, 2 + 2

        mov     ax, [tokensCount]
        mov     cx, sizeOfToken     ; cx - size of element
        mul     cx

        lea     dx, [tokens]        ; dx - begin ptr
        add     ax, dx              ; ax - end ptr

@@foreachLoop:
        push    dx
        call    printToken
        pop     dx

        add     dx, cx
        cmp     dx, ax
        jb      @@foreachLoop

        ret

debugPrint endp


include token.asm

include string.asm

include print.asm




usage db "usage: program [/?] [resident (21 | 27)] [delete (gentle | hard)]", 24h


end start

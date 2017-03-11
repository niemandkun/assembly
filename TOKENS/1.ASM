.model tiny
locals

; constants:

argcPtr = 80h
argvPtr = argcPtr + 1

.code
        org     100h

start:
        xor     dx, dx
        mov     dl, cs:[argcPtr]
        push    dx

        mov     dx, argvPtr
        push    dx

        call    parseArgs

        add     sp, 2 + 2

        call    debugPrint

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


aFlag Token <flag, flagLen>
helpFlag Token <help, helpLen>

flag db "/a"
flagLen = $ - flag

help db "/?"
helpLen = $ - help

lexemes dw aFlag, helpFlag
lexemesLen = $ - lexemes

usage db "usage: program [/A] [/B] [/C] [/?]", 24h

end start

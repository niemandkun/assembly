upperCaseZ = "Z" ;5Ah
upperCaseA = "A" ;41h
lowerCaseA = "a"
space = " "
backSlash = "\"

toLowerDelta = lowerCaseA - upperCaseA

strToLower proc c near uses ax cx si di
        arg @@strPtr:word, @@strLength:word

        mov     cx, [@@strLength]
        mov     si, [@@strPtr]
        mov     di, [@@strPtr]

@@startLoop:
        lodsb

        cmp     al, upperCaseZ
        ja      @@isNotLetter
        cmp     al, upperCaseA
        jb      @@isNotLetter

        add     al, toLowerDelta
        stosb
        jmp     @@endLoop

@@isNotLetter:
        inc     di

@@endLoop:
        dec     cx
        jg      @@startLoop

        ret

strToLower endp


strUnescape proc c near uses si di bx cx
        arg @@strPtr:word, @@strLength:word

        mov     si, [@@strPtr]
        mov     di, si
        mov     cx, [@@strLength]
        xor     bx, bx      ; unescaped string length
        xor     dl, dl      ; escaped flag

@@unescapeLoop:
        lodsb
        cmp     al, backslash
        jne     @@isNotEscape

        test    dl, dl
        jnz     @@isNotEscape

        mov     dl, 1
        jmp     @@continue


@@isNotEscape:
        xor     dl, dl
        inc     bx
        stosb

@@continue:
        dec     cx
        jg      @@unescapeLoop

        mov     ax, bx
        ret

strUnescape endp

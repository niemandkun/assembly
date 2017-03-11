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


strCompare proc c near uses si di cx
        arg @@first:word, @@second:word
        ; compare two zero terminated strings
        ; returns: ax = 0 if strings are equal, 1 otherwise

        mov     si, [@@first]
        mov     di, [@@second]

        push    si
        call    strLength
        add     sp, 2
        mov     cx, ax

        push    di
        call    strLength
        add     sp, 2
        cmp     cx, ax
        jne     @@compareFail

@@compareLoop:
        cmpsb
        jne     @@compareFail
        dec     cx
        jnz     @@compareLoop
        xor     ax, ax
        jmp     @@return

@@compareFail:
        mov     ax, 1

@@return:
        ret

strCompare endp


strLength proc c near uses si cx
        arg @@string:word
        ; calculate a length of the zero terminated string
        ; returns: ax = length of the given string

        mov     si, [@@string]
        xor     cx, cx

@@lengthLoop:
        lodsw
        test    al, al
        jz      @@finish
        inc     cx
        test    ah, ah
        jz      @@finish
        inc     cx
        jmp     @@lengthLoop

@@finish:
        mov     ax, cx
        ret

strLength endp


strPrint proc c near uses ax bx dx
        ; print zero terminated string
        arg @@string:word

        mov     dx, [@@string]

        push    dx
        call    strLength
        add     sp, 2

        mov     bx, dx
        add     bx, ax

        mov     byte ptr [bx], 24h
        mov     ah, 09h
        int     21h

        mov     byte ptr [bx], 00h

        ret

strPrint endp

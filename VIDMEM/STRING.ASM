upperCaseZ = "Z"
upperCaseA = "A"
upperCaseF = "F"
lowerCaseA = "a"
lowerCaseF = "f"
lowerCaseZ = "z"
space = " "
backSlash = "\"

toLowerDelta = lowerCaseA - upperCaseA
toUpperDelta = -toLowerDelta

digitsOffset = "0"
lowerCaseOffset = lowerCaseA - 10
upperCaseOffset = upperCaseA - 10


parseByte proc c near uses si bx
        arg @@strPtr:word
        ; returns: al - byte, ah = 0 on succes
        ; al = ?, ah = 1 on error

        mov     si, [@@strPtr]

        xor     ax, ax

        lodsb
        call    parseDigit
        test    ah, ah
        jnz     @@finish

        mov     cl, 4
        shl     ax, cl
        mov     bl, al

        lodsb
        call    parseDigit
        test    ah, ah
        jnz     @@finish

        add     al, bl

@@finish:
        ret

parseByte endp


parseDigit:
        ;   args: al -- hexadecimal digit character
        ;   returns: al = number if no errors, ah = 1 otherwise

        cmp     al, lowerCaseA
        jb      @@upper
        cmp     al, lowerCaseF
        ja      @@error
        sub     al, lowerCaseOffset
        ret

@@upper:
        cmp     al, upperCaseA
        jb      @@digit
        cmp     al, upperCaseF
        ja      @@error
        sub     al, upperCaseOffset
        ret

@@digit:
        cmp     al, "0"
        jb      @@error
        cmp     al, "9"
        ja      @@error
        sub     al, digitsOffset
        ret

@@error:
        mov     ah, 1
        ret


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


strToUpper proc c near uses ax cx si di
        arg @@strPtr:word, @@strLength:word

        mov     cx, [@@strLength]
        mov     si, [@@strPtr]
        mov     di, [@@strPtr]

@@startLoop:
        lodsb

        cmp     al, lowerCaseZ
        ja      @@isNotLetter
        cmp     al, lowerCaseA
        jb      @@isNotLetter

        add     al, toUpperDelta
        stosb
        jmp     @@endLoop

@@isNotLetter:
        inc     di

@@endLoop:
        dec     cx
        jg      @@startLoop

        ret

strToUpper endp


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

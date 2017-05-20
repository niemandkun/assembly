text segment
        assume  cs:text, ds:text, es:text

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


parseInt proc c near uses bx cx si
        arg @@strPtr:word
        ; returns: ax = integer, cf = 0 on succes
        ; ax = ?, cf = 1 on error

        mov     si, ss:[@@strPtr]

        xor     bx, bx      ; accumulator

@@cycle:
        xor     ax, ax

        lodsb
        test    al, al
        jz      @@finish

        call    parseDigit
        jc      @@finish

        xchg    ax, bx
        mov     cl, 0Ah
        mul     cl
        xchg    ax, bx

        add     bx, ax

@@finish:
        mov     ax, bx
        ret

parseInt endp


parseDigit:
        ;   args: al -- hexadecimal digit character
        ;   returns: ax = number if no errors, cf = 1 otherwise

        clc

        cmp     al, "0"
        jb      @@error
        cmp     al, "9"
        ja      @@error
        sub     al, digitsOffset
        ret

@@error:
        stc
        ret


strToLower proc c near uses ax cx si di
        arg @@strPtr:word, @@strLength:word

        mov     cx, ss:[@@strLength]
        mov     si, ss:[@@strPtr]
        mov     di, ss:[@@strPtr]

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

        mov     cx, ss:[@@strLength]
        mov     si, ss:[@@strPtr]
        mov     di, ss:[@@strPtr]

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

        mov     si, ss:[@@strPtr]
        mov     di, si
        mov     cx, ss:[@@strLength]
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

        mov     si, ss:[@@second]
        mov     di, ss:[@@first]

        push    si
        call    strLength
        add     sp, 2
        mov     cx, ax

        push    ds
        mov     ax, es
        mov     ds, ax

        push    di
        call    strLength
        add     sp, 2

        pop     ds

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

        mov     si, ss:[@@string]
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

        mov     dx, ss:[@@string]

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

text ends

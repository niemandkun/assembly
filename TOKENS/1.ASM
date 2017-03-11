        .model tiny
        locals

        .code
        org     100h

; constants:

argcPtr = 80h
argvPtr = argcPtr + 1

start:
        mov     bp, sp

        xor     dx, dx
        mov     dl, cs:[argcPtr]
        push    dx

        mov     dx, argvPtr
        push    dx

        call    strToLower
        call    splitTokens
        add     sp, 2 * 2

        push    ax
        call    unescapeAndTerminate
        add     sp, 2

        int     20h

String struc
    @ptr dw ?
    @length dw ?
String ends


stringDecl:
aFlag String <flag, flagLen>
sizeOfString = $ - stringDecl

helpFlag String <help, helpLen>

flag db "/a"
flagLen = $ - flag

help db "/?"
helpLen = $ - help

lexemes dw aFlag, helpFlag
lexemesLen = $ - lexemes

tokens String 64 dup(<>)

usage db "usage: program [/A] [/B] [/C] [/?]", 24h


unescapeAndTerminate proc c near uses ax bx cx dx
        arg @@tokensCount:word

        mov     ax, [@@tokensCount]
        mov     cx, sizeOfString    ; cx - size of element
        mul     cx

        lea     dx, [tokens]
        add     ax, dx              ; ax - begin ptr
        xchg    ax, dx              ; dx - end ptr

@@foreachLoop:
        push    ax
        call    unescapeToken
        call    terminateToken
        call    printToken
        pop     ax

        add     ax, cx
        cmp     ax, dx
        jb      @@foreachLoop

        ret

unescapeAndTerminate endp


foreach proc c near uses dx
        arg @@funcPtr:word, @@beginPtr:word, @@sizeOfElement:word, @@endPtr:word

        mov     dx, [@@beginPtr]

@@foreachLoop:
        push    dx
        call    [@@funcPtr]
        add     sp, 2

        add     dx, [@@sizeOfElement]
        cmp     dx, [@@endPtr]
        jb      @@foreachLoop

        ret

foreach endp


splitTokens proc c near
        arg @@strPtr:word, @@strLength:word
        ; fills array of tokens with data
        ; returns count of tokens

        mov     si, [@@strPtr]
        mov     cx, [@@strLength]
        lea     di, [tokens]
        xor     dx, dx

@@readTokenLoop:
        push    cx
        push    si
        call    readSpaces
        add     sp, 2 * 2

        sub     cx, ax
        add     si, ax

        test    cx, cx
        jle     @@finish

        mov     al, [si]        ; peek first character and choose what to do

@@singleQuote:
        cmp     al, 27h
        je      @@quote

@@doubleQuote:
        cmp     al, 22h
        jne     @@space

@@quote:
        inc     si
        dec     cx
        push    ax
        jmp     @@readToken

@@space:
        mov     al, 20h
        push    ax

@@readToken:
        mov     ax, si
        stosw                   ; remember start of the token

        push    cx
        push    si
        call    readToken
        add     sp, 2 * 3

        stosw                   ; remember length of the token

        add     ax, 1
        add     si, ax
        sub     cx, ax

        inc     dx

        test    cx, cx
        jg      @@readTokenLoop

@@finish:
        mov     ax, dx
        ret

splitTokens endp


readSpaces proc c near uses cx si
        arg @@strPtr:word, @@strLength:word
        ; returns count of spaces

        mov     si, [@@strPtr]
        mov     cx, [@@strLength]

@@readLoop:
        lodsb
        dec     cx
        jle     @@finish

        cmp     al, 20h     ; space
        je      @@readLoop

        cmp     al, 09h     ; tab
        je      @@readLoop

@@finish:
        mov     ax, [@@strPtr]      ; 0 1 2 3 4 5 6 7 8 9
        sub     si, ax              ; # # _ # # # # _ # #
        xchg    si, ax              ;       ^         ^
        dec     ax                  ;       ax        si
        ret                         ; thus, len = si - ax - 1

readSpaces endp


readToken proc c near uses bx cx dx si
        arg @@strPtr:word, @@strLength:word, @@terminateCharacter:word
        ; returns length of read

        mov     dx, [@@terminateCharacter]
        mov     bh, 5Ch     ; escape character ('\\')
        xor     bl, bl      ; escaped flag

        mov     si, [@@strPtr]
        mov     cx, [@@strLength]

@@readLoop:
        lodsb
        cmp     al, dl              ; is character terminating?
        jne     @@nonTerminating

        test    bl, bl              ; is character not escaped?
        jnz     @@nonTerminating

        dec     si
        jmp     @@finish            ; if so, end reading

@@nonTerminating:
        cmp     al, bh              ; is character escaping?
        jne     @@nonEscaping

        test    bl, bl              ; is character not escaped?
        jnz     @@nonEscaping

        mov     bl, 1               ; if so, set escaped = true
        jmp     @@loopEnd

@@nonEscaping:
        xor     bl, bl

@@loopEnd:
        dec     cx
        jg      @@readLoop

@@finish:
        mov     ax, [@@strPtr]
        sub     si, ax
        xchg    si, ax
        ret

readToken endp


unescapeToken proc c near uses bx dx
        arg @@tokenPtr:word

        mov     bx, [@@tokenPtr]

        mov     dx, [bx].@length
        push    dx

        mov     dx, [bx].@ptr
        push    dx

        call    strUnescape

        add     sp, 2 * 2
        mov     word ptr [bx].@length, ax
        ret

unescapeToken endp


terminateToken proc c near uses ax bx cx
        arg @@tokenPtr:word

        mov     bx, [@@tokenPtr]

        mov     ax, [bx].@length
        mov     bx, [bx].@ptr
        add     bx, ax

        mov     byte ptr [bx], 24h

        ret

terminateToken endp


printToken proc c near uses ax bx dx
        arg @@tokenPtr:word

        mov     bx, [@@tokenPtr]

        mov     dx, [bx].@ptr
        mov     ah, 09h
        int     21h

        mov     dl, 0Ah
        mov     ah, 02h
        int     21h

        ret

printToken endp


strToLower proc c near uses ax cx si di
        arg @@strPtr:word, @@strLength:word

        mov     cx, [@@strLength]
        mov     si, [@@strPtr]
        mov     di, [@@strPtr]

@@startLoop:
        lodsb

        cmp     al, 5Ah         ; code of upper-case Z
        ja      @@isNotLetter
        cmp     al, 41h         ; code of upper-case A
        jb      @@isNotLetter

        add     al, 20h
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
        cmp     al, 5Ch
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


printSegmentOffset proc c near uses dx
        arg @@segmentAddress:word, @@offset:word

        mov     dx, [@@segmentAddress]
        push    dx
        call    printWord
        pop     dx

        mov     dx, 3Ah     ; ":"
        push    dx
        call    putChar
        pop     dx

        mov     dx, [@@offset]
        push    dx
        call    printWord
        pop     dx

        mov     dx, 20h     ; "\n"
        push    dx
        call    putChar
        pop     dx

        ret

printSegmentOffset endp


putChar proc c near uses ax dx
        arg @@charToPrint:word

        mov     ah, 02h
        mov     dx, [@@charToPrint]
        int     21h

        ret

putChar endp


printWord proc c near uses dx
        arg @@wordToPrint:word

        mov     dx, 04h     ; add up to 4 leading zeros to adjust length
        push    dx

        mov     dx, 10h     ; radix
        push    dx

        mov     dx, [@@wordToPrint]
        push    dx

        call    printNumber

        add     sp, 3 * 2

        ret

printWord endp


printNumber proc c near uses ax bx cx dx
        arg @@numberToPrint:word, @@radix:word, @@totalLength:word

        mov     ax, [@@numberToPrint]
        mov     bx, [@@radix]
        xor     cx, cx              ; counter for characters to print

@@divisionLoop:
        xor     dx, dx
        div     bx
        push    dx                  ; push remainder to stack
        inc     cx
        test    ax, ax
        jnz     @@divisionLoop

        mov     ah, 02h
        mov     dx, 30h             ; print leading zeros if need
        mov     bx, [@@totalLength]

@@leadingZerosLoop:
        cmp     bx, cx
        jle     @@printLoop
        int     21h
        dec     bx
        jmp     @@leadingZerosLoop

@@printLoop:
        pop     dx
        cmp     dl, 0Ah
        jb      @@isDecimal
        add     dl, 07h             ; if hex number

@@isDecimal:
        add     dl, 30h
        int     21h
        dec     cx
        jnz     @@printLoop

        ret

printNumber endp


end start

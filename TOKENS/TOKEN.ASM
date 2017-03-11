Token struc
    @ptr dw ?
    @length dw ?
Token ends


sizeOfToken = 4


tokensCount dw ?
tokens Token 64 dup(<>)

parseArgs proc c near uses ax dx
        arg @@argvPtr:word, @@argc:word
        ; returns: count of tokens in ax, pointer to tokens in bx

        mov     dx, [@@argc]
        push    dx

        mov     dx, [@@argvPtr]
        push    dx

        call    strToLower
        call    splitTokens
        add     sp, 2 + 2

        mov     [tokensCount], ax

        push    ax
        call    unescapeAndTerminate
        add     sp, 2

        ret

parseArgs endp


unescapeAndTerminate proc c near uses ax bx cx dx
        arg @@tokensCount:word

        mov     ax, [@@tokensCount]
        mov     cx, sizeOfToken     ; cx - size of element
        mul     cx

        lea     dx, [tokens]
        add     ax, dx              ; ax - begin ptr
        xchg    ax, dx              ; dx - end ptr

@@foreachLoop:
        push    ax
        call    unescapeToken
        call    terminateToken
        pop     ax

        add     ax, cx
        cmp     ax, dx
        jb      @@foreachLoop

        ret

unescapeAndTerminate endp


splitTokens proc c near uses bx cx dx si di
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

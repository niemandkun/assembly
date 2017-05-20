text segment
        assume  cs:text, ds:text, es:nothing

Token struc
    @ptr dw ?
    @length dw ?
Token ends

sizeOfToken = 4

argcPtr = 80h
argvPtr = argcPtr + 1


lengthFlag db '/LENGTH', 00h
lengthFlagShort db '/L', 00h

collisionFlag db '/COLLISION', 00h
collisionFlagShort db '/C', 00h

itemsFlag db '/ITEMS', 00h
itemsFlagShort db '/I', 00h

deathFlag db 'DEATH', 00h
cutFlag db 'CUT', 00h
nothingFlag db 'NOTHING', 00h


parseArgs proc c near uses bx cx dx

        mov     ax, ds
        mov     es, ax

        call    splitArgsCom

        mov     ax, cs
        mov     es, ax

        mov     cx, cs:[tokensCount]
        test    cx, cx
        jz      @@finish

        lea     bx, [tokens]

@@checkLoop:
        push    bx
        call    processParameter
        add     sp, 2

        sub     cx, ax
        jle     @@finish

        mov     dx, sizeOfToken
        mul     dx
        add     bx, ax
        jmp     @@checkLoop

@@finish:
        ret

parseArgs endp


flagCmp proc
        ;   si -- parameter (in data segment)
        ;   di -- flag (in code segment)
        ;   dx -- short flag (in code segment)

        push    si

        push    dx
        call    strCompare
        add     sp, 2
        mov     dx, ax

        push    di
        call    strCompare
        add     sp, 4

        and     ax, dx

        ret

flagCmp endp


singleFlagCmp macro flag
        push    si
        lea     di, [flag]
        push    di
        call    strCompare
        add     sp, 2+2
        test    ax, ax
endm


storeCollisionType proc
        ; bx -- pointer to Token
        ; ret: ax = 1 if error, 0 otherwise

        xor     ax, ax
        mov     si, cs:[bx].@ptr
        test    si, si
        jz      @@error

@@death:
        singleFlagCmp deathFlag
        jne     @@cut
        ; TODO: handle parameter
        ret

@@cut:
        singleFlagCmp cutFlag
        jne     @@nothing
        ; TODO: handle parameter
        ret

@@nothing:
        singleFlagCmp nothingFlag
        jne     @@error
        ; TODO: handle parameter
        ret

@@error:
        mov     ax, 1
        ret

storeCollisionType endp


processParameter proc c near uses bx cx si di
        arg @@tokenPtr:word

        mov     bx, ss:[@@tokenPtr]

        mov     si, cs:[bx].@ptr
        mov     cx, cs:[bx].@length

@@collision:
        lea     di, [collisionFlag]
        lea     dx, [collisionFlagShort]
        call    flagCmp
        test    ax, ax
        jnz     @@length

        add     bx, sizeOfToken
        call    storeCollisionType
        test    ax, ax
        jnz     @@invalid

        mov     ax, 2
        jmp     @@finish

@@length:
        lea     di, [lengthFlag]
        lea     dx, [lengthFlagShort]
        call    flagCmp
        test    ax, ax
        jnz     @@items

        add     bx, sizeOfToken
        mov     bx, cs:[bx].@ptr
        push    bx
        call    parseInt
        add     sp, 2

        ; TODO: handle parameter

        mov     ax, 2
        jmp     @@finish

@@items:
        lea     di, [itemsFlag]
        lea     dx, [itemsFlagShort]
        call    flagCmp
        test    ax, ax
        jnz     @@invalid

        add     bx, sizeOfToken
        mov     bx, cs:[bx].@ptr
        push    bx
        call    parseInt
        add     sp, 2

        ; TODO: handle parameter

        mov     ax, 2
        jmp     @@finish

@@invalid:
        jmp     printUsageAndExit

@@finish:
        ret

processParameter endp


printUsageAndExit proc near
        mov     ax, cs
        mov     ds, ax
        lea     dx, [help]
        mov     ah, 09h
        int     21h
        mov     ah, 4ch
        mov     al, 1
        int     21h
printUsageAndExit endp


help db                                                                                0Ah
     db "Usage: 2.COM [/N] [/M MODE] [/P PAGE] [/C COLOR] [/LL LASTLINE] [/?]",        0Ah
     db                                                                                0Ah
     db "Print fullscreen ASCII-table and exit by pressing any key.",                  0Ah
     db                                                                                0Ah
     db "Parameters:",                                                                 0Ah
     db "    /N, /NOBLINK   - Disable blinking",                                       0Ah
     db "    /M, /MODE      - Video mode to use (default 3)",                          0Ah
     db "    /P, /PAGE      - Video page to use (default 0)",                          0Ah
     db "    /C, /CAPTION   - Set color for caption",                                  0Ah
     db "    /LL, /LASTLINE - Set output mode for last line in mode 7h",               0Ah
     db "                     possible values: BRIGHT, BLINK, REVERSED, BRIGHTBLINK",  0Ah
     db                                                                                0Ah
     db "    /?, /HELP      - Show this help message and exit",                        0Ah
     db                                                                                0Ah
     db "    Mode   Valid Pages",                                                      0Ah
     db "      0       0 - 7   ",                                                      0Ah
     db "      1       0 - 7   ",                                                      0Ah
     db "      2       0 - 3   ",                                                      0Ah
     db "      3       0 - 3   ",                                                      0Ah
     db "      7         0     ",                                                      0Ah
     db                                                                                24h


splitArgsCom proc c near uses dx

        xor     dx, dx
        mov     dl, ds:[argcPtr]
        push    dx

        mov     dx, argvPtr
        push    dx

        call    splitArgs
        add     sp, 2 + 2

        ret

splitArgsCom endp


splitArgs proc c near uses ax dx
        arg @@argvPtr:word, @@argc:word
        ; returns: count of tokens in ax, pointer to tokens in bx

        mov     dx, ss:[@@argc]

        test    dx, dx
        jz      @@finish

        push    dx

        mov     dx, ss:[@@argvPtr]
        push    dx

        call    strToUpper
        call    splitTokens
        add     sp, 2 + 2

        mov     cs:[tokensCount], ax
        mov     cx, sizeOfToken     ; cx - size of element
        mul     cx

        lea     dx, cs:[tokens]
        add     ax, dx
        mov     cs:[tokensExclusiveEndPtr], ax

        call    unescapeAndTerminate

@@finish:
        ret

splitArgs endp


unescapeAndTerminate proc c near uses ax bx cx dx

        mov     cx, sizeOfToken             ; cx - size of element
        lea     ax, cs:[tokens]                ; ax - begin ptr
        mov     dx, cs:[tokensExclusiveEndPtr] ; dx - end ptr

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


splitTokens proc c near uses bx cx dx si di es
        arg @@strPtr:word, @@strLength:word
        ; fills array of tokens with data
        ; returns count of tokens

        mov     ax, cs
        mov     es, ax

        mov     si, ss:[@@strPtr]
        mov     cx, ss:[@@strLength]
        lea     di, cs:[tokens]
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

        mov     si, ss:[@@strPtr]
        mov     cx, ss:[@@strLength]

@@readLoop:
        lodsb
        dec     cx
        jle     @@finish

        cmp     al, 20h     ; space
        je      @@readLoop

        cmp     al, 09h     ; tab
        je      @@readLoop

@@finish:
        mov     ax, ss:[@@strPtr]   ; 0 1 2 3 4 5 6 7 8 9
        sub     si, ax              ; # # _ # # # # _ # #
        xchg    si, ax              ;       ^         ^
        dec     ax                  ;       ax        si
        ret                         ; thus, len = si - ax - 1

readSpaces endp


readToken proc c near uses bx cx dx si
        arg @@strPtr:word, @@strLength:word, @@terminateCharacter:word
        ; returns length of read

        mov     dx, ss:[@@terminateCharacter]
        mov     bh, 5Ch     ; escape character ('\\')
        xor     bl, bl      ; escaped flag

        mov     si, ss:[@@strPtr]
        mov     cx, ss:[@@strLength]

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
        mov     ax, ss:[@@strPtr]
        sub     si, ax
        xchg    si, ax
        ret

readToken endp


unescapeToken proc c near uses bx dx
        arg @@tokenPtr:word

        mov     bx, ss:[@@tokenPtr]

        mov     dx, cs:[bx].@length
        push    dx

        mov     dx, cs:[bx].@ptr
        push    dx

        call    strUnescape

        add     sp, 2 * 2
        mov     word ptr cs:[bx].@length, ax
        ret

unescapeToken endp


terminateToken proc c near uses ax bx cx
        arg @@tokenPtr:word

        mov     bx, ss:[@@tokenPtr]

        mov     ax, cs:[bx].@length
        mov     bx, cs:[bx].@ptr
        add     bx, ax

        mov     byte ptr ds:[bx], 00h

        ret

terminateToken endp


tokensCount dw ?
tokens Token 64 dup(?)
tokensExclusiveEndPtr dw ?

text ends

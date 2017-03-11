resident = 0
residentFlag db "resident", 00h
residentFlagLength = $ - residentFlag

int21 = 1
int21Flag db "21", 00h
int21FlagLength = $ - int21Flag

int27 = 2
int27Flag db "27", 00h
int27FlagLength = $ - int27Flag

delete = 3
deleteFlag db "delete", 00h
deleteFlagLength = $ - deleteFlag

gentle = 4
gentleFlag db "gentle", 00h
gentleFlagLength = $ - gentleFlag

hard = 5
hardFlag db "hard", 00h
hardFlagLength = $ - hardFlag

help = 6
helpFlag db "/?", 00h
helpFlagLength = $ - helpFlag


acceptableLexemes:
    Token <residentFlag, residentFlagLength>
    Token <int21Flag, int21FlagLength>
    Token <int27Flag, int27FlagLength>
    Token <deleteFlag, deleteFlagLength>
    Token <gentleFlag, gentleFlagLength>
    Token <hardFlag, hardFlagLength>
    Token <helpFlag, helpFlagLength>

acceptableLexemesLength = $ - acceptableLexemes


lexemesCount = 7
lexemes dw lexemesCount dup(0)
lexemesExclusiveEndPtr = $

matchLexemes proc c near uses ax bx cx si di

        lea     di, [lexemes]
        lea     si, [acceptableLexemes]
        mov     cx, si
        add     cx, acceptableLexemesLength

@@matchLoop:
        push    si
        call    matchSingleLexeme
        add     sp, 2

        mov     word ptr [di], ax

        add     di, 2
        add     si, sizeOfToken

        cmp     si, cx
        jl      @@matchLoop

        ret

matchLexemes endp


matchSingleLexeme proc c near uses bx dx si di
        arg @@lexeme:word
        ; returns:
        ; ax = token offset if lexeme is present in tokens;
        ; ax = 0 otherwise

        mov     bx, [@@lexeme]
        mov     si, [bx].@ptr
        push    si

        lea     bx, [tokens]
        mov     dx, [tokensExclusiveEndPtr]

@@compareLoop:
        mov     di, [bx].@length

        test    di, di
        jz      @@continue

        mov     di, [bx].@ptr
        push    di
        call    strCompare
        add     sp, 2

        test    ax, ax
        jnz     @@continue

        mov     ax, bx
        mov     word ptr [bx].@length, 0h
        jmp     @@finish

@@continue:
        add     bx, sizeOfToken
        cmp     bx, dx
        jl      @@compareLoop

        xor     ax, ax

@@finish:
        add     sp, 2
        ret

matchSingleLexeme endp


validateTokens proc c near uses

        lea     si, [tokens]
        lea     di, [tokensExclusiveEndPtr]

@@checkLoop:
        mov     bx, [si].@length
        test    bx, bx
        jnz     @@invalidArgsError

        add     si, sizeOfToken
        cmp     si, di
        jne     @@checkLoop

        jmp     @@finish

@@invalidArgsError:
        lea     dx, [@@invalidArgsMessage]
        mov     ah, 09h
        int     21h

        mov     dx, [si].@ptr
        push    dx
        call    strPrint
        add     sp, 2

        int     20h

@@invalidArgsMessage db "Invalid parameter: ", 24h

@@finish:
        ret

validateTokens endp

residentFlag db "resident", 00h
residentFlagLength = $ - residentFlag

int21Flag db "21", 00h
int21FlagLength = $ - int21Flag

int27Flag db "27", 00h
int27FlagLength = $ - int27Flag

deleteFlag db "delete", 00h
deleteFlagLength = $ - deleteFlag

gentleFlag db "gentle", 00h
gentleFlagLength = $ - gentleFlag

hardFlag db "hard", 00h
hardFlagLength = $ - hardFlag

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
acceptableLexemesCount = 7


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
        mov     di, [bx].@ptr
        push    di
        call    strCompare
        add     sp, 2

        test    ax, ax
        jnz     @@compareFails

        mov     ax, bx
        jmp     @@finish

@@compareFails:
        add     bx, sizeOfToken
        cmp     bx, dx
        jl      @@compareLoop

        xor     ax, ax

@@finish:
        add     sp, 2
        ret

matchSingleLexeme endp

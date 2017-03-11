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

        int     20h


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

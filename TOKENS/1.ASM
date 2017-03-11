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
        add     sp, 2 + 2

handleArgs:
        mov     bx, [help]
        test    bx, bx
        jnz     showHelp

        mov     bx, [resident]
        test    bx, bx
        jnz     makeResident

        mov     bx, [delete]
        test    bx, bx
        jnz     deleteResident

        jmp     ambiguousCallError

makeResident:
        lea     dx, [residentMsg]
        mov     ah, 09h
        int     21h
        int     20h

residentMsg db "Make resident", 0Ah, 24h

deleteResident:
        lea     dx, [deleteMsg]
        mov     ah, 09h
        int     21h
        int     20h

deleteMsg db "Delete resident", 0Ah, 24h


showHelp:
        mov     ah, 09h
        lea     dx, [usage]
        int     21h
        lea     dx, [helpMsg]
        int     21h
        int     20h

helpMsg:
    db 0Ah, 0Ah
    db "Install resident and delete it if possible", 0Ah
    db 0Ah
    db "Parameters:", 0Ah
    db 0Ah
    db "/R - terminate and stay resident, listening to int 2Fh", 0Ah
    db "        27 - using int 27h", 0Ah
    db "        21 - using function 31h of int 21h", 0Ah
    db 0Ah
    db "/D - delete resident", 0Ah
    db "        GENTLE - delete only if possible", 0Ah
    db "        HARD - forced delete", 0Ah
    db 0Ah
    db "/? - show this help message and exit", 0Ah
    db 24h


ambiguousCallError:

        lea     dx, [ambiguousCallMessage]
        mov     ah, 09h
        int     21h

        lea     dx, [usage]
        int     21h

        jmp     exit

ambiguousCallMessage db "Ambiguous call: you should use only one top-level parameter", 0Ah, 24h

exit:
        int     20h

include token.asm

include lexeme.asm

include string.asm

include print.asm

end start

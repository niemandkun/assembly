.model tiny
locals
.386

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
        mov     bx, [resident]
        test    bx, bx
        jnz     makeResident

        mov     bx, [delete]
        test    bx, bx
        jnz     deleteResident

        mov     bx, [help]
        test    bx, bx
        jnz     showHelp

noTopLevelArgsError:
        lea     dx, [noTopLevelArgsMessage]
        jmp     errorEnd

ambiguousCallError:
        lea     dx, [ambiguousCallMessage]
        jmp     errorEnd

invalidArgsError:
        lea     dx, [invalidArgsMessage]
        jmp     errorEnd

additionalArgsError:
        lea     dx, [additionalArgsMessage]

errorEnd:
        mov     ah, 09h
        int     21h
        lea     dx, [usage]
        int     21h
        int     20h

conflict macro first, other, handler
        mov     ax, [first]
    irp xx, other
        add     ax, [xx]
    endm
        cmp     ax, [first]
        jne     handler
endm


required macro first, other, handler
        mov     ax, [first]
    irp xx, other
        add     ax, [xx]
    endm
        cmp     ax, [first]
        je      handler
endm


makeResident:
        conflict resident, <help,delete>, ambiguousCallError
        conflict resident, <gentle,hard>, invalidArgsError

        mov     ax, bx          ; check conflicted parameters
        add     ax, [help]
        add     ax, [delete]
        cmp     ax, bx
        jne     ambiguousCallError

        mov     ax, bx
        add     ax, [gentle]
        add     ax, [hard]
        cmp     ax, bx
        jne     invalidArgsError

        xor     ax, ax
        add     ax, [int21]
        add     ax, [int27]
        test    ax, ax
        jz      additionalArgsError

        lea     dx, [residentMsg]
        mov     ah, 09h
        int     21h
        int     20h

residentMsg db "Make resident", 0Ah, 24h

deleteResident:
        mov     ax, bx
        add     ax, [help]
        add     ax, [resident]
        cmp     ax, bx
        jne     ambiguousCallError

        mov     ax, bx
        add     ax, [int21]
        add     ax, [int27]
        cmp     ax, bx
        jne     invalidArgsError

        xor     ax, ax
        add     ax, [gentle]
        add     ax, [hard]
        test    ax, ax
        jz      additionalArgsError

        lea     dx, [deleteMsg]
        mov     ah, 09h
        int     21h
        int     20h

deleteMsg db "Delete resident", 0Ah, 24h

showHelp:
        mov     ax, bx
        add     ax, [delete]
        add     ax, [resident]
        cmp     ax, bx
        jne     ambiguousCallError

        mov     ax, bx
        add     ax, [int21]
        add     ax, [int27]
        add     ax, [gentle]
        add     ax, [hard]
        cmp     ax, bx
        jne     invalidArgsError

        mov     ah, 09h
        lea     dx, [usage]
        int     21h
        lea     dx, [helpMsg]
        int     21h
        int     20h


include token.asm

include lexeme.asm

include string.asm

include print.asm


noTopLevelArgsMessage:
    db "Any top level parameter is required", 0Ah, 24h

ambiguousCallMessage:
    db "Ambiguous call: you should use only one top-level parameter", 0Ah, 24h

invalidArgsMessage:
    db "Command contains invalid parameters", 0Ah, 24h

additionalArgsMessage:
    db "Additional command line args are expected", 0Ah, 24h

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

end start

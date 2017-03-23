.model tiny
locals
.386

include macros.asm

; constants:

argcPtr = 80h
argvPtr = argcPtr + 1

.code
        org     100h
start:
        jmp     initEntry


include tsr.asm


initEntry:
        lea     ax, [tsrCodeEnd]

        xor     dx, dx
        mov     dl, cs:[argcPtr]
        push    dx

        mov     dx, argvPtr
        push    dx

        call    parseArgs
        add     sp, 2 + 2

handleArgs:
        conflicting <help, deploy, remove>, ambiguousCallError
        conflicting <help, remove, int21, int27>, invalidArgsError
        conflicting <help, deploy, gentle, resize, hard>, invalidArgsError

        requiring deploy, <int21, int27>, additionalArgsError
        requiring remove, <gentle, resize, hard>, additionalArgsError

        mov     bx, [deploy]
        test    bx, bx
        jnz     deployResident

        mov     bx, [remove]
        test    bx, bx
        jnz     removeResident

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
        jmp     exit

deployResident:
        mov     bx, [int21]
        push    bx
        call    tryInstallTsr
        add     sp, 2
        jmp     exit

removeResident:
        mov     bx, [resize]
        push    bx
        mov     bx, [gentle]
        push    bx
        call    uninstallTsr
        add     sp, 2
        jmp     exit

showHelp:
        mov     ah, 09h
        lea     dx, [usage]
        int     21h
        lea     dx, [helpMsg]
        int     21h

exit:
        int     20h


include args.asm

include string.asm

include print.asm

include deploy.asm


noTopLevelArgsMessage:
    db "At least one top level parameter is required.", 0Ah, 24h

ambiguousCallMessage:
    db "Ambiguous call: you should use only one parameter on each level.", 0Ah, 24h

invalidArgsMessage:
    db "Command contains invalid or conflicting parameters.", 0Ah, 24h

additionalArgsMessage:
    db "Additional command line args are expected.", 0Ah, 24h

helpMsg:
    db 0Ah
    db "Deploy resident and remove it if possible.", 0Ah
    db 0Ah
    db "Parameters:", 0Ah
    db 0Ah
    db "DEPLOY - install resident that is listening to int 2Fh", 0Ah
    db "        27h - using int 27h", 0Ah
    db "        21h - using function 31h of int 21h", 0Ah
    db 0Ah
    db "REMOVE - remove resident", 0Ah
    db "        HARD - forced remove", 0Ah
    db "        GENTLE - print error if unable to remove", 0Ah
    db "        RESIZE - resize resident if unable to remove", 0Ah
    db 0Ah
    db "HELP - show this help message and exit", 0Ah
    db 24h

usage:
    db "Usage: 1 [HELP] [DEPLOY (21h | 27h)] [REMOVE (GENTLE | RESIZE | HARD)]", 0Ah, 24h

end start

        .model tiny
        .code
        org 100h
start:

                                ; clean registers for further use
        xor     bx, bx          ; bx: number of characters in current line
        xor     cx, cx          ; cx: ascii code of character to print
        xor     dx, dx

        mov     ah, 02h         ; print character DOS API service

@@loop_start:
        mov     dl, cl          ; put current character into dl

        int     21h             ; print character from register dl

        inc     bl
        cmp     bl, 10h         ; if have not print 10h characters yet
        jne     @@end           ; do nothing

        xor     bl, bl          ; else
        mov     dl, 0Ah         ; print line break character
        int     21h

        mov     dl, 0Dh         ; and print carriage return character
        int     21h

@@end:
        push    ax

        xor     ax, ax
        int     16h

        pop     ax

        inc     cl              ; calculate next character's code
        cmp     cl, 21h         ; if not every character is printed
        jne     @@loop_start    ; begin loop from the beginning

        ret                     ; exit otherwise

end start

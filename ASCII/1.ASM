        .model tiny
        .code
        org 100h
start:

        mov     si, 2000h

@@1:
                                ; clean registers for further use
        xor     bx, bx          ; bx: number of characters in current line
        xor     cx, cx          ; cx: ascii code of character to print
        xor     dx, dx


        mov     ah, 02h         ; print character DOS API service

loop_start:
        cmp     cl, 1Bh         ; escape character
        je      print_space

        cmp     cl, 0Dh         ; carriage return
        je      print_space

        cmp     cl, 07h         ; all characters in range from 07h to 0Ah
        jb      print_char      ; are control characters
                                ; should print space instead of them
        cmp     cl, 0Ah
        ja      print_char

print_space:
        mov     dl, 20h         ; put space character into dl
        jmp     continue

print_char:
        mov     dl, cl          ; put current character into dl

continue:
;        int     21h             ; print character from register dl

        inc     bl
        cmp     bl, 10h         ; if didnt print 10h characters yet
        jne     end             ; do nothing

        xor     bl, bl          ; else
        mov     dl, 0Ah         ; print line break character
;        int     21h

        mov     dl, 0Dh         ; and print carriage return character
;        int     21h

end:
        inc     cl              ; calculate next character's code
        cmp     cl, 0h          ; if not every character is printed
        jne     loop_start      ; begin loop from the beginning


        dec      si
        test     si, si
        jnz      @@1

        ret                     ; exit otherwise

end start

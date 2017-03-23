        .model tiny
        .code
        org 100h
start:

        mov     si, 2000h

@@1:
        xor     dl, dl
        xor     bl, bl
        lea     di, buffer
        cld

loop_start:
        cmp     dl, 24h         ; $ character
        je      print_space

        cmp     dl, 1Bh         ; escape character
        je      print_space

        cmp     dl, 0Dh         ; carriage return
        je      print_space

        cmp     dl, 07h         ; control characters in range from 07h to 0Ah
        jb      print_char

        cmp     dl, 0Ah
        ja      print_char

print_space:
        mov     al, 20h         ; put space character into dl
        jmp     continue

print_char:
        mov     al, dl          ; put current character into dl
        mov     cl, 01h

continue:
        stosb

        inc     bl
        cmp     bl, 10h
        jne     loop_end

        xor     bl, bl
        mov     al, 0Ah
        stosb

        mov     al, 0Dh
        stosb

loop_end:
        inc     dl
        cmp     dl, 00h
        jne     loop_start

        mov     [di], "$"

        lea     dx, buffer
        mov     ah, 09h
;        int     21h


        dec      si
        test     si, si
        jnz      @@1

        ret

buffer  db    1024  dup (?)

end start

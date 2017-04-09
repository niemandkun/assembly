colon = 3Ah
newLine = 0Ah


printSegmentOffset proc c near uses dx
        arg @@segmentAddress:word, @@offset:word

        mov     dx, [@@segmentAddress]
        push    dx
        call    printWord
        pop     dx

        mov     dx, colon
        push    dx
        call    putChar
        pop     dx

        mov     dx, [@@offset]
        push    dx
        call    printWord
        pop     dx

        mov     dx, newLine
        push    dx
        call    putChar
        pop     dx

        ret

printSegmentOffset endp


putChar proc c near uses ax dx
        arg @@charToPrint:word

        mov     ax, [@@charToPrint]
        mov     ah, 0Ah
        mov     cx, 1
        xor     bx, bx
        int     10h

        mov     ah, 03h
        xor     bx, bx
        int     10h

        inc     dl

        mov     ah, 02h
        xor     bx, bx
        int     10h

        ret

putChar endp


printNewLine proc c near uses ax dx

        lea     dx, [@@newLine]
        mov     ah, 09h
        int     21h

        ret

@@newLine db 0Dh, 0Ah, 24h

printNewLine endp


printByte proc c near uses dx
        arg @@byteToPrint:word

        mov     dx, 02h
        push    dx
        mov     dx, 10h
        push    dx
        mov     dx, [@@byteToPrint]
        push    dx
        call    printNumber
        add     sp, 3 * 2
        mov     ah, 02h
        mov     dx, "h"
        int     21h
        ret

printByte endp


printWord proc c near uses dx
        arg @@wordToPrint:word

        mov     dx, 04h     ; add up to 4 leading zeros to adjust length
        push    dx

        mov     dx, 10h     ; radix
        push    dx

        mov     dx, [@@wordToPrint]
        push    dx

        call    printNumber

        add     sp, 3 * 2

        ret

printWord endp


printNumber proc c near uses ax bx cx dx
        arg @@numberToPrint:word, @@radix:word, @@totalLength:word

        mov     ax, [@@numberToPrint]
        mov     bx, [@@radix]
        xor     cx, cx              ; counter for characters to print

@@divisionLoop:
        xor     dx, dx
        div     bx
        push    dx                  ; push remainder to stack
        inc     cx
        test    ax, ax
        jnz     @@divisionLoop

        mov     ah, 02h
        mov     dx, 30h             ; print leading zeros if need
        mov     bx, [@@totalLength]

@@leadingZerosLoop:
        cmp     bx, cx
        jle     @@printLoop
        int     21h
        dec     bx
        jmp     @@leadingZerosLoop

@@printLoop:
        pop     dx
        cmp     dl, 0Ah
        jb      @@isDecimal
        add     dl, 07h             ; if hex number

@@isDecimal:
        add     dl, 30h
        int     21h
        dec     cx
        jnz     @@printLoop

        ret

printNumber endp

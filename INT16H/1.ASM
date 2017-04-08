model tiny
locals

.code
        org     100h

start:

        lea     dx, [header]
        mov     ah, 09h
        int     21h

@@cycle:
        call    printNewLine

        xor     ax, ax
        int     16h

        push    ax
        call    printKeyInfo
        pop     ax

        cmp     ax, 2E03h   ; ^C
        jne     @@cycle

        ret

printTab proc c near uses ax dx

        mov     dl, 09h
        mov     ah, 02h
        int     21h
        int     21h
        ret

printTab endp


printKeyInfo proc c near uses bx
        arg @@keyCode:word

        mov     bx, [@@keyCode]
        ; assume scancode in bh, ASCII code in bl

        xor     ax, ax
        mov     al, bl
        push    ax
        call    putChar

        call    printTab

        call    printByte
        add     sp, 2

        call    printTab

        xor     ax, ax
        mov     al, bh
        push    ax
        call    printByte
        add     sp, 2

        call    printTab

        push    bx
        call    printKeyName
        add     sp, 2

        ret

printKeyInfo endp


printKeyName proc c near uses bx cx dx si
        arg @@keyCode:word

        mov     dx, [@@keyCode]
        lea     si, [scancodes]

@@searchLoop:
        mov     bx, si
        add     bx, 08h

        ; none
        lea     cx, [none]
        lodsw
        cmp     ax, 0FFFFh
        je      @@notFound
        cmp     ax, dx
        je      @@printKeyName

        ; shift
        lea     cx, [shift]
        lodsw
        cmp     ax, dx
        je      @@printKeyName

        ; ctrl
        lea     cx, [ctrl]
        lodsw
        cmp     ax, dx
        je      @@printKeyName

        ; alt
        lea     cx, [alt]
        lodsw
        cmp     ax, dx
        je      @@printKeyName

        add     si, 02h
        jmp     @@searchLoop

@@printKeyName:
        mov     dx, cx
        mov     ah, 09h
        int     21h

        mov     dx, [bx]
        int     21h
        jmp     @@finish

@@notFound:
        lea     dx, [unknownKey]
        mov     ah, 09h
        int     21h

@@finish:
        ret

printKeyName endp

header db "Character", 09h, "ASCII code", 09h, "Scancode", 09h, "Key", 0Dh, 0Ah
       db "----------------------------------------------------------", 24h

unknownKey db "Unknown", 24h

none    db "", 24h
ctrl    db "Ctrl + ", 24h
shift   db "Shift + ", 24h
alt     db "Alt + ", 24h

keyA    db "A", 24h
keyB    db "B", 24h
keyC    db "C", 24h
keyD    db "D", 24h
keyE    db "E", 24h
keyF    db "F", 24h
keyG    db "G", 24h
keyH    db "H", 24h
keyI    db "I", 24h
keyJ    db "J", 24h
keyK    db "K", 24h
keyL    db "L", 24h
keyM    db "M", 24h
keyN    db "N", 24h
keyO    db "O", 24h
keyP    db "P", 24h
keyQ    db "Q", 24h
keyR    db "R", 24h
keyS    db "S", 24h
keyT    db "T", 24h
keyU    db "U", 24h
keyV    db "V", 24h
keyW    db "W", 24h
keyX    db "X", 24h
keyY    db "Y", 24h
keyZ    db "Z", 24h

key1    db "1", 24h
key2    db "2", 24h
key3    db "3", 24h
key4    db "4", 24h
key5    db "5", 24h
key6    db "6", 24h
key7    db "7", 24h
key8    db "8", 24h
key9    db "9", 24h
key0    db "0", 24h

keyHyphen       db "Hyphen", 24h
keyEquals       db "Equals", 24h
keyLbracket     db "Left bracket", 24h
keyRbracket     db "Right bracket", 24h
keySemicolon    db "Semicolon", 24h
keyQuote        db "Quote", 24h
keyPrime        db "Prime", 24h
keyBackslash    db "Backslash", 24h
keyComma        db "Comma", 24h
keyDot          db "Dot", 24h
keySlash        db "Slash", 24h

keyF1   db "F1", 24h
keyF2   db "F2", 24h
keyF3   db "F3", 24h
keyF4   db "F4", 24h
keyF5   db "F5", 24h
keyF6   db "F6", 24h
keyF7   db "F7", 24h
keyF8   db "F8", 24h
keyF9   db "F9", 24h
keyF10  db "F10", 24h
keyF11  db "F11", 24h
keyF12  db "F12", 24h

keyBackSpace        db "BackSpace", 24h
keyDel              db "Del", 24h
keyDown             db "Down Arrow", 24h
keyEnd              db "End", 24h
keyEnter            db "Enter", 24h
keyEsc              db "Esc", 24h
keyHome             db "Home", 24h
keyIns              db "Ins", 24h
keyKeypadFive       db "Keypad 5", 24h
keyKeypadAsterisk   db "Keypad *", 24h
keyKeypadMinus      db "Keypad -", 24h
keyKeypadPlus       db "Keypad +", 24h
keyKeypadSlash      db "Keypad /", 24h
keyLeft             db "Left Arrow", 24h
keyPgDn             db "PgDn", 24h
keyPgUp             db "PgUp", 24h
keyPrtSc            db "PrtSc", 24h
keyRight            db "Right Arrow", 24h
keySpace            db "SpaceBar", 24h
keyTab              db "Tab", 24h
keyUp               db "Up Arrow", 24h


scancodes:

;  normal  shift   ctrl    alt     name
;  00h     02h     04h     06h     08h
dw 01E61h, 01E41h, 01E01h, 01E00h, offset keyA
dw 03062h, 03042h, 03002h, 03000h, offset keyB
dw 02E63h, 02E43h, 02E03h, 02E00h, offset keyC
dw 02064h, 02044h, 02004h, 02000h, offset keyD
dw 01265h, 01245h, 01205h, 01200h, offset keyE
dw 02166h, 02146h, 02106h, 02100h, offset keyF
dw 02267h, 02247h, 02207h, 02200h, offset keyG
dw 02368h, 02348h, 02308h, 02300h, offset keyH
dw 01769h, 01749h, 01709h, 01700h, offset keyI
dw 0246Ah, 0244Ah, 0240Ah, 02400h, offset keyJ
dw 0256Bh, 0254Bh, 0250Bh, 02500h, offset keyK
dw 0266Ch, 0264Ch, 0260Ch, 02600h, offset keyL
dw 0326Dh, 0324Dh, 0320Dh, 03200h, offset keyM
dw 0316Eh, 0314Eh, 0310Eh, 03100h, offset keyN
dw 0186Fh, 0184Fh, 0180Fh, 01800h, offset keyO
dw 01970h, 01950h, 01910h, 01900h, offset keyP
dw 01071h, 01051h, 01011h, 01000h, offset keyQ
dw 01372h, 01352h, 01312h, 01300h, offset keyR
dw 01F73h, 01F53h, 01F13h, 01F00h, offset keyS
dw 01474h, 01454h, 01414h, 01400h, offset keyT
dw 01675h, 01655h, 01615h, 01600h, offset keyU
dw 02F76h, 02F56h, 02F16h, 02F00h, offset keyV
dw 01177h, 01157h, 01117h, 01100h, offset keyW
dw 02D78h, 02D58h, 02D18h, 02D00h, offset keyX
dw 01579h, 01559h, 01519h, 01500h, offset keyY
dw 02C7Ah, 02C5Ah, 02C1Ah, 02C00h, offset keyZ

dw 00231h, 00221h, 00000h, 07800h, offset key1
dw 00332h, 00340h, 00300h, 07900h, offset key2
dw 00433h, 00423h, 00000h, 07A00h, offset key3
dw 00534h, 00524h, 00000h, 07B00h, offset key4
dw 00635h, 00625h, 00000h, 07C00h, offset key5
dw 00736h, 0075Eh, 0071Eh, 07D00h, offset key6
dw 00837h, 00826h, 00000h, 07E00h, offset key7
dw 00938h, 0092Ah, 00000h, 07F00h, offset key8
dw 00A39h, 00A28h, 00000h, 08000h, offset key9
dw 00B30h, 00B29h, 00000h, 08100h, offset key0

dw 00C2Dh, 00C5Fh, 00C1Fh, 08200h, offset keyHyphen
dw 00D3Dh, 00D2Bh, 08300h, 00000h, offset keyEquals
dw 01A5Bh, 01A7Bh, 01A1Bh, 01A00h, offset keyLbracket
dw 01B5Dh, 01B7Dh, 01B1Dh, 01B00h, offset keyRbracket
dw 0273Bh, 0273Ah, 02700h, 00000h, offset keySemicolon
dw 02827h, 02822h, 00000h, 00000h, offset keyQuote
dw 02960h, 0297Eh, 00000h, 00000h, offset keyPrime
dw 02B5Ch, 02B7Ch, 02B1Ch, 02600h, offset keyBackslash
dw 0332Ch, 0333Ch, 00000h, 00000h, offset keyComma
dw 0342Eh, 0343Eh, 00000h, 00000h, offset keyDot
dw 0352Fh, 0353Fh, 00000h, 00000h, offset keySlash

dw 03B00h, 05400h, 05E00h, 06800h, offset keyF1
dw 03C00h, 05500h, 05F00h, 06900h, offset keyF2
dw 03D00h, 05600h, 06000h, 06A00h, offset keyF3
dw 03E00h, 05700h, 06100h, 06B00h, offset keyF4
dw 03F00h, 05800h, 06200h, 06C00h, offset keyF5
dw 04000h, 05900h, 06300h, 06D00h, offset keyF6
dw 04100h, 05A00h, 06400h, 06E00h, offset keyF7
dw 04200h, 05B00h, 06500h, 06F00h, offset keyF8
dw 04300h, 05C00h, 06600h, 07000h, offset keyF9
dw 04400h, 05D00h, 06700h, 07100h, offset keyF10
dw 08500h, 08700h, 08900h, 08B00h, offset keyF11
dw 08600h, 08800h, 08A00h, 08C00h, offset keyF12

dw 00E08h, 00E08h, 00E7Fh, 00E00h, offset keyBackSpace
dw 05300h, 0532Eh, 09300h, 0A300h, offset keyDel
dw 05000h, 05032h, 09100h, 0A000h, offset keyDown
dw 04F00h, 04F31h, 07500h, 09F00h, offset keyEnd
dw 01C0Dh, 01C0Dh, 01C0Ah, 0A600h, offset keyEnter
dw 0011Bh, 0011Bh, 0011Bh, 00100h, offset keyEsc
dw 04700h, 04737h, 07700h, 09700h, offset keyHome
dw 05200h, 05230h, 09200h, 0A200h, offset keyIns
dw 00000h, 04C35h, 08F00h, 00000h, offset keyKeypadFive
dw 0372Ah, 00000h, 09600h, 03700h, offset keyKeypadAsterisk
dw 04A2Dh, 04A2Dh, 08E00h, 04A00h, offset keyKeypadMinus
dw 04E2Bh, 04E2Bh, 00000h, 04E00h, offset keyKeypadPlus
dw 0352Fh, 0352Fh, 09500h, 0A400h, offset keyKeypadSlash
dw 04B00h, 04B34h, 07300h, 09B00h, offset keyLeft
dw 05100h, 05133h, 07600h, 0A100h, offset keyPgDn
dw 04900h, 04939h, 08400h, 09900h, offset keyPgUp
dw 00000h, 00000h, 07200h, 00000h, offset keyPrtSc
dw 04D00h, 04D36h, 07400h, 09D00h, offset keyRight
dw 03920h, 03920h, 03920h, 03920h, offset keySpace
dw 00F09h, 00F00h, 09400h, 0A500h, offset keyTab
dw 04800h, 04838h, 08D00h, 09800h, offset keyUp

dw 0FFFFh   ; EOT

include print.asm

end start

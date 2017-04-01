        .model  tiny
        locals
        .386

biosRomSegment = 0040h
biosVideoSegment = 0B800h
biosVideoMemory = 0B000h

biosActiveVideoMode = 0049h
biosTextColumnsCount = 004Ah
biosVideoPageOffset = 004Eh
biosCursorPosition = 0050h
biosActiveVideoPage = 0062h
biosVideoCardPort = 0063h
biosVideoCrtMode = 0065h

videoInterrupt = 10h
videoSetMode = 00h
videoSetPage = 05h
videoSetCursor = 02h
videoGetCursor = 03h

videoPageLengthBytes = 1000h
videoPageLengthWords =  videoPageLengthBytes / 2
videoPageLengthParags = videoPageLengthBytes / 16

kbdInterrupt = 16h
kbdRead = 00h

dosInterrupt = 21h
dosGetTime = 2Ch

.code
        org     100h

start:
        call    splitArgsCom
        call    parseArgs
        call    checkPageModeCorrect

        call    saveVideoMode
        call    saveScreenState
        call    saveCursor

        call    changeVideoMode
        call    clearScreen

        call    disableBlinkIfNeed

        call    initRandom
        call    showAscii

        call    waitKey

        call    restoreVideoMode
        call    restoreScreenState
        call    restoreCursor

        call    restoreBlink

        ret


restoreBlink proc c near uses ax es dx bx

        ; CGA and MDA
        mov     ax, biosRomSegment
        mov     es, ax
        mov     dx, es:[biosVideoCardPort]
        add     dx, 4

        mov     bl, cs:[oldCrtRegister]
        and     bl, 20h                     ; mask value by 0010 0000 (to keep bit 5)
        mov     al, es:[biosVideoCrtMode]
        or      al, bl

        out     dx, al
        mov     es:[biosVideoCrtMode], al

        ret

restoreBlink endp


disableBlinkIfNeed proc c near uses bx dx es

        mov     bl, [disableBlink]
        test    bl, bl
        jz      @@finish

        ; VGA and EGA:
        mov     ax, 1003h
        xor     bx, bx
        int     videoInterrupt

        ; CGA and MDA:
        mov     ax, biosRomSegment
        mov     es, ax
        mov     dx, es:[biosVideoCardPort]  ; get port address of the card
        add     dx, 4                       ; 3x8h register

        mov     al, es:[biosVideoCrtMode]   ; get current value of Mode Select Register
        and     al, 0DFh                    ; mask value by 1101 1111 (to clear bit 5)
        out     dx, al                      ; disable blink
        mov     es:[biosVideoCrtMode], al   ; save the new setting
        mov     cs:[oldCrtRegister], al

@@finish:
        ret

disableBlinkIfNeed endp


clearScreen proc c near uses es di ax cx

        call    getPageStart
        mov     es, ax

        xor     di, di
        xor     ax, ax

        mov     cx, videoPageLengthWords
        rep     stosw

        ret

clearScreen endp


showAscii proc c near uses es bx dx di cx

        mov     al, [currentVideoMode]
        cmp     al, 7
        jne     @@useRandomLastLine

        lea     dx, [mode7color]
        mov     [lastLine], dx
        jmp     @@beginPrint

@@useRandomLastLine:
        lea     dx, [random]
        mov     [lastLine], dx

@@beginPrint:

        call    getPageStart
        mov     es, ax

        mov     ax, biosRomSegment
        push    ds
        mov     ds, ax

        mov     bp, ds:[biosTextColumnsCount]
        pop     ds

        mov     di, bp
        sub     di, 16*2        ; address of first character

        shl     bp, 1           ; BP := length of one line in bytes

        mov     ax, 3           ; caption offset (lines)
        mul     bp
        add     ax, 7*2         ; offset of caption from beginning of the table

        add     ax, di
        push    ax
        call    printCaption
        add     sp, 2

        mov     ax, (25-14)/2   ; vertical offset
        mul     bp

        add     di, ax

        xor     si, si          ; character
        xor     cx, cx          ; lines counter

@@printLoop:

        mov     ax, cx
        shl     ax, 1
        lea     bx, [lines]
        add     bx, ax
        mov     ax, cs:[bx]

        push    ax
        push    si
        push    di

        call    printAsciiLine
        add     sp, 2 * 3

        add     si, 10h
        add     di, bp

        inc     cx
        cmp     cx, 10h
        jne     @@printLoop

        ret

showAscii endp


white:
        mov     ah, 0Fh
        ret

cyan:
        mov     ah, 03h
        ret

magenta:
        mov     ah, 05h
        ret

blinking:
        mov     ah, 082h
        ret

colorful:
        mov     ah, al
        ret

mode7color:
        mov     ah, [monoColor]
        ret

random:
        push    bx
        push    ax

@@rndLoop:
        call    getRandom
        and     ah, 00001111b
        test    ah, ah
        jz      @@rndLoop

        mov     bh, ah
        pop     ax
        mov     ah, bh

        pop     bx

        ret


lines dw colorful, blinking, cyan, magenta, 11 dup(random)
lastLine dw mode7color


printAsciiLine proc c near uses di bx cx
        arg @@startAddress:word, @@startCharacter:word, @@colorFunc:word

        mov     di, [@@startAddress]
        mov     bx, [@@startCharacter]
        mov     cx, 10h

@@lineLoop:

        mov     ax, bx
        call    [@@colorFunc]
        stosw

        mov     al, 20h
        stosw

        inc     bx
        dec     cx
        jnz     @@lineLoop

        ret

printAsciiLine endp


printCaption proc c near uses ax cx di si
        arg @@startAddress:word

        mov     di, [@@startAddress]

        mov     ah, [captionColor]

        lea     si, [modeStr]
        mov     cx, modeStrLen

@@print1:
        lodsb
        stosw
        dec     cx
        jnz     @@print1

        mov     al, [currentVideoMode]
        add     al, 30h
        stosw

        mov     al, 20h
        mov     cx, 3
        rep     stosw

        lea     si, [pageStr]
        mov     cx, pageStrLen

@@print2:
        lodsb
        stosw
        dec     cx
        jnz     @@print2

        mov     al, [currentVideoPage]
        add     al, 30h
        stosw

        ret

printCaption endp


modeStr db "mode: "
modeStrLen = $ - modeStr

pageStr db "page: "
pageStrLen = $ - pageStr


waitKey proc near

        mov     ax, kbdRead
        int     kbdInterrupt
        ret

waitKey endp


changeVideoMode proc near

        mov     ah, videoSetMode
        mov     al, [currentVideoMode]
        int     videoInterrupt

        mov     ah, videoSetPage
        mov     al, [currentVideoPage]
        int     videoInterrupt

        ret

changeVideoMode endp


saveVideoMode proc c near uses bx es

        call    getCurrentVideoParams
        mov     word ptr [oldVideoParams], ax

        ret

saveVideoMode endp


restoreVideoMode proc c near uses bx

        mov     bx, word ptr [oldVideoParams]

        mov     ah, videoSetPage
        mov     al, bl
        int     videoInterrupt

        mov     ah, videoSetMode
        mov     al, bh
        int     videoInterrupt

        ret

restoreVideoMode endp


saveScreenState proc c near uses si di ds es cx ax

        call    getPageStart
        mov     ds, ax

        xor     si, si
        lea     di, [screenBuffer]

        mov     cx, videoPageLengthWords
        rep     movsw

        ret

saveScreenState endp


restoreScreenState proc c near uses si di cx es

        call    getPageStart
        mov     es, ax

        lea     si, [screenBuffer]
        xor     di, di

        mov     cx, videoPageLengthWords
        rep     movsw

        ret

restoreScreenState endp


saveCursor proc c near uses bx dx

        mov     ax, biosRomSegment
        mov     es, ax

        mov     dx, es:[biosCursorPosition]


        mov     [oldCursorPosition], dx

        ret

saveCursor endp


restoreCursor proc c near uses bx dx

        call    getCurrentVideoParams
        mov     bh, al
        mov     dx, [oldCursorPosition]
        mov     ah, videoSetCursor
        int     videoInterrupt

        ret

restoreCursor endp


getPageStart proc c near uses cx es bx

        mov     ax, biosRomSegment
        mov     es, ax

        mov     ax, es:[biosVideoPageOffset]
        mov     cl, 4
        shr     ax, cl

        mov     bl, es:[biosActiveVideoMode]
        cmp     bl, 7
        je      @@7thMode

@@otherMode:
        add     ax, biosVideoSegment
        jmp     @@finish

@@7thMode:
        add     ax, biosVideoMemory

@@finish:
        ret

getPageStart endp


getCurrentVideoParams proc c near uses es

        ; al -- current video mode, ah -- current video page

        mov     ax, biosRomSegment
        mov     es, ax

        mov     ah, es:[biosActiveVideoMode]
        mov     al, es:[biosActiveVideoPage]

        ret

getCurrentVideoParams endp


initRandom proc c near uses ax cx dx


@@cycle:
        mov     ah, dosGetTime
        int     dosInterrupt

        test    dx, dx
        jz      @@cycle

        mov     cs:[randomSeed], dx

        ret

initRandom endp


getRandom proc c near uses bx cx dx
        ; seed = (seed * LARGE_PRIME_1) % LARGE_PRIME_2

        mov     ax, cs:[randomSeed]

        xor     dx, dx
        mov     bx, 27361
        mul     bx

        xor     dx, dx
        mov     bx, 27751
        div     bx

        xchg    ax, dx
        mov     cs:[randomSeed], ax

        ret

getRandom endp


captionColor db 07h

currentVideoParams:
currentVideoMode db 03h
currentVideoPage db 00h

disableBlink db 00h

monoColor db 02h

include string.asm

include args.asm


randomSeed dw ?

oldVideoParams:
oldVideoPage db ?
oldVideoMode db ?

oldCrtRegister db ?

oldCursorPosition dw ?

screenBuffer db videoPageLengthBytes dup(?)


end start

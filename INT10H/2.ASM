        .model  tiny
        locals

biosRomSegment = 0040h
biosVideoSegment = 0B800h
biosTextColumnsCount = 004Ah
biosActiveVideoPage = 0062h
biosActiveVideoMode = 0049h
biosVideoPageOffset = 004Eh

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
        call    saveVideoMode
        call    saveScreenState
        call    saveCursor

        call    changeVideoMode
        call    clearScreen

        call    initRandom
        call    showAscii

        call    waitKey

        call    restoreVideoMode
        call    restoreScreenState
        call    restoreCursor

        ret


clearScreen proc c near uses es di ax cx

        call    getPageStart
        mov     es, ax

        xor     di, di
        xor     ax, ax

        mov     cx, videoPageLengthWords
        rep     stosw

        ret

clearScreen endp


showAscii proc c near uses ds es bx dx di cx

        mov     ax, biosRomSegment
        mov     ds, ax

        mov     bp, ds:[biosTextColumnsCount]

        mov     di, bp
        sub     di, 16+16           ; address of first character

        shl     bp, 1               ; length of one line in bytes

        mov     ax, (25-16)/2       ; vertical offset
        mul     bp
        add     di, ax

        xor     si, si              ; character
        xor     cx, cx              ; lines counter

        call    getPageStart
        mov     es, ax

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


lines dw colorful, blinking, cyan, magenta, 12 dup(random)


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


waitKey proc near

        mov     ax, kbdRead
        int     kbdInterrupt
        ret

waitKey endp


changeVideoMode proc near

        mov     ah, videoSetPage
        mov     al, 1
        int     videoInterrupt

        mov     ah, videoSetMode
        mov     al, 3
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

        call    getCurrentVideoParams
        mov     bh, al

        mov     ah, videoGetCursor
        int     videoInterrupt

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


getPageStart proc c near uses cx es

        mov     ax, biosRomSegment
        mov     es, ax

        mov     ax, es:[biosVideoPageOffset]
        mov     cl, 4
        shr     ax, cl

        add     ax, biosVideoSegment

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

        mov     ah, dosGetTime
        int     dosInterrupt

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


randomSeed dw ?

oldVideoParams:
oldVideoPage db ?
oldVideoMode db ?

oldCursorPosition dw ?

screenBuffer db videoPageLengthBytes dup(?)


end start

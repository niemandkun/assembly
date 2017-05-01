buffersLength       equ     20

                    db      01h
pressBuffer         db      buffersLength dup (0)
pressBufferEnd      equ     $
pressBufferHead     dw      offset pressBuffer

                    db      02h
releaseBuffer       db      BuffersLength dup (0)
releaseBufferEnd    equ     $
releaseBufferHead   dw      offset releaseBuffer


pressedKeysBitmap   dw      258/8 dup (0)


; contract: HEAD always points to a FIRST FREE cell in a buffer

; buffer is empty, iff HEAD = INCLUSIVE_BUFFER_START
; where BUFFER_START is an address of a fist byte of the buffer

; buffer is full, iff HEAD = EXCLUSIVE_BUFFER_END
; where EXCLUSIVE_BUFFER_END is an addres of a first byte after the buffer


putKey proc near

        ; args:
        ;       al - some scancode
        ; ret:
        ;       c=0 if ok, c=1 if buffer overflow

        push    ax
        cmp     al, 0E0h            ; if aux. scancode, ignore it
        je      @@finish

        mov     ah, al
        and     ah, 80h             ; check press or release
        jnz     @@release           ; and decide what to do

        call    pressKey
        jmp     @@finish
@@release:
        call    releaseKey
@@finish:
        pop     ax
        ret

putKey endp


pressKey proc near

        ; args:
        ;       al - scancode of pressed key
        ; ret:
        ;       c=0 if ok, c=1 if error

        ; check, that buffer has enough space
        cmp     word ptr cs:[pressBufferHead], offset pressBufferEnd
        jne     @@putKey
        stc
        ; if buffer is full, c=1 and ret
        ret

@@putKey:
        push    bx
        push    cx
        mov     bx, word ptr cs:[pressBufferHead]
        mov     cx, offset pressBuffer

        ; check, that key is not pressed twice
        call    testKeyInBuffer
        jnc     @@doPut

        ; if key is pressed twice, set c=1 and ret
        stc
        jmp     @@finish

@@doPut:
        ; put pressed key into buffer
        mov     byte ptr cs:[bx], al
        inc     word ptr cs:[pressBufferHead]
        clc

@@finish:
        pop     cx
        pop     bx
        ret

pressKey endp


testKeyInBuffer proc near

        ; args:
        ;       al - key to test
        ;       bx - buffer head
        ;       cx - inclusive buffer start
        ; ret:
        ;       c=1 if key in press buffer, c=0 otherwise

@@checkLoop:
        dec     bx
        cmp     bx, cx
        jl      @@notPressed
        cmp     byte ptr cs:[bx], al
        jne     @@checkLoop

        stc
        ret

@@notPressed:
        clc
        ret

testKeyInBuffer endp


releaseKey proc near

        ; args:
        ;       al - scancode of released key
        ; ret:
        ;       c=0 if ok, c=1 if error

        ; if pressBuffer is empty, there is nothing to release
        ; this situation is impossible and if we are here
        ; something is probably going wrong
        cmp     word ptr cs:[pressBufferHead], offset pressBuffer
        je      @@error

        ; check, that release buffer is not full
        cmp     word ptr cs:[releaseBufferHead], offset releaseBufferEnd
        je      @@error

        ; if al is a release scancode
        ; to simplify further work, we convert it into
        ; according press scancode
        and     al, 7Fh

        ; finally, put the scancode into release buffer
        push    bx
        mov     bx, word ptr cs:[releaseBufferHead]
        mov     byte ptr cs:[bx], al
        inc     word ptr cs:[releaseBufferHead]
        pop     bx

        ; pop released keys from both buffers
        call    popReleasedKeys

        ; set c = 0 and ret
        clc
        ret

@@error:
        stc
        ret

releaseKey endp


popReleasedKeys proc near

        ; args:
        ;       none
        ; ret:
        ;       none

        ; pop equal scancodes from both buffers
        ; starting from buffer heads

        push    si
        mov     si, word ptr cs:[pressBufferHead]

        push    di
        mov     di, word ptr cs:[releaseBufferHead]

        push    ax

@@popLoop:
        dec     si
        dec     di
        mov     al, byte ptr cs:[si]
        cmp     al, byte ptr cs:[di]
        je      @@popLoop

        pop     ax

        inc     di
        mov     word ptr cs:[releaseBufferHead], di
        pop     di

        inc     si
        mov     word ptr cs:[pressBufferHead], si
        pop     si

        ret

popReleasedKeys endp


peekKey proc near

        ; args:
        ;       none
        ;
        ; ret:
        ;       c=0 and al=scancode of last pressed key, which
        ;       is still not released at a time of procedure call
        ;       if such a key is available
        ;
        ;       or c=1 and garbage in al if there is no such a key

        ; check, that press buffer is not empty
        cmp     word ptr cs:[pressBufferHead], offset pressBuffer
        jne     @@peek
        stc
        ret

@@peek:
        ; peek scancode from buffer and return it
        push    bx
        mov     bx, word ptr cs:[pressBufferHead]
        dec     bx
        mov     al, byte ptr cs:[bx]
        pop     bx
        clc
        ret

peekKey endp


markKeyPressed proc near

        ; args:
        ;       al - key to mark
        ; ret:
        ;       none

        pusha
        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        or      dx, ax
        mov     word ptr cs:[bx], dx

        popa
        ret

markKeyPressed endp


markKeyReleased proc near

        ; args:
        ;       al - key to mark
        ; ret:
        ;       none

        pusha
        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        not     ax
        and     dx, ax
        mov     word ptr cs:[bx], dx

        popa
        ret

markKeyReleased endp


testKeyPressed proc near
        ; args:
        ;       al - key to test
        ; ret:
        ;       none
        pusha
        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        not     ax
        and     dx, ax
        mov     word ptr cs:[bx], dx

        popa
        ret

testKeyPressed endp


getAddressMask proc near

        ; args:
        ;       al - scancode
        ; ret:
        ;       bx - offset of word in memory
        ;       ax - mask of bit in word

        xor     ah, ah
        mov     bx, 16          ; address of word in al
        div     bx              ; offset of bit in word in ah

        mov     bl, al
        add     bx, offset keysBitmap

        mov     cl, ah
        mov     ax, 1
        sal     ax, cl

        ret

getAddressMask endp

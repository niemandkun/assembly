bufferLength        equ     20

                    db      01h
pressBuffer         db      bufferLength dup (0)
pressBufferEnd      equ     $
pressBufferHead     dw      offset pressBuffer

keysBitmap   dw      128/8 dup (0)


; contract: HEAD always points to a FIRST FREE cell in a buffer

; buffer is empty, iff HEAD = INCLUSIVE_BUFFER_START
; where BUFFER_START is an address of a fist byte of the buffer

; buffer is full, iff HEAD = EXCLUSIVE_BUFFER_END
; where EXCLUSIVE_BUFFER_END is an addres of a first byte after the buffer


putKey proc near

        ; args:
        ;       al - some scancode
        ; ret:
        ;       cf=0 if ok, cf=1 if buffer overflow

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
        ;       cf=0 if ok, cf=1 if error

        ; check, that buffer has enough space
        cmp     word ptr cs:[pressBufferHead], offset pressBufferEnd
        jne     @@checkKey
        stc
        ret

@@checkKey:
        ; check, that key is not pressed twice
        call    testKeyPressed
        jnc     @@putKey
        stc
        ret

@@putKey:
        ; set key in bitmap
        call    markKeyPressed

        ; put pressed key into buffer
        push    bx
        mov     bx, word ptr cs:[pressBufferHead]
        mov     byte ptr cs:[bx], al
        inc     word ptr cs:[pressBufferHead]
        pop     bx
        clc
        ret

pressKey endp


releaseKey proc near

        ; args:
        ;       al - scancode of released key
        ; ret:
        ;       cf = 0

        ; if got release scancode, turn it into press scancode
        and     al, 7Fh

        ; release key
        call    markKeyReleased

        ; pop released keys out of buffer
        call    popReleasedKeys

        clc
        ret

releaseKey endp


popReleasedKeys proc near

        ; args:
        ;       none
        ; ret:
        ;       none

        push    ax
        push    si
        mov     si, word ptr cs:[pressBufferHead]

@@popLoop:
        dec     si
        cmp     si, offset pressBuffer
        jl      @@finish
        mov     al, byte ptr cs:[si]
        call    testKeyPressed
        jnc     @@popLoop

@@finish:
        inc     si
        mov     word ptr cs:[pressBufferHead], si
        pop     si
        pop     ax

        ret

popReleasedKeys endp


peekKey proc near

        ; args:
        ;       none
        ;
        ; ret:
        ;       cf=0 and al=scancode of last pressed key, which
        ;       is still not released at a time of procedure call
        ;       if such a key is available
        ;
        ;       or cf=1 and garbage in al if there is no such a key

        ; check, that press buffer is not empty
        cmp     word ptr cs:[pressBufferHead], offset pressBuffer
        jne     @@peek
        stc
        ret

@@peek:
        ; peek scancode from buffer and return it
        push    bx
        mov     bx, word ptr cs:[pressBufferHead]
        mov     al, byte ptr cs:[bx-1]
        pop     bx
        clc
        ret

peekKey endp


markKeyPressed proc near

        ; args:
        ;       al - key to mark
        ; ret:
        ;       none

        push    ax
        push    bx
        push    cx
        push    dx

        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        or      dx, ax
        mov     word ptr cs:[bx], dx

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

markKeyPressed endp


markKeyReleased proc near

        ; args:
        ;       al - key to mark
        ; ret:
        ;       none

        push    ax
        push    bx
        push    cx
        push    dx

        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        not     ax
        and     dx, ax
        mov     word ptr cs:[bx], dx

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

markKeyReleased endp


testKeyPressed proc near
        ; args:
        ;       al - key to test
        ; ret:
        ;       cf=1 if pressed, cf=0 if not

        push    ax
        push    bx
        push    cx
        push    dx

        call    getAddressMask

        mov     dx, word ptr cs:[bx]
        and     dx, ax
        jz      @@notPressed
        stc
        jmp     @@finish

@@notPressed:
        clc

@@finish:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
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
        div     bl              ; offset of bit in word in ah

        mov     bl, al
        add     bx, offset keysBitmap

        mov     cl, ah
        mov     ax, 1
        sal     ax, cl

        ret

getAddressMask endp

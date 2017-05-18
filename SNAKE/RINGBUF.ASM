bufferLength = 20

buffer  db      bufferLength dup (0)

bufferEnd = $

head    dw      offset buffer
tail    dw      offset buffer

ringBufferWrite proc near
        push    bx
        mov     bx, cs:head
        mov     byte ptr cs:[bx], al
        mov     ax, bx
        inc     word ptr cs:head
        cmp     word ptr cs:head, offset bufferEnd
        jne     @@noHeadResumption
        mov     cs:head, offset buffer
@@noHeadResumption:
        mov     bx, cs:head
        cmp     bx, cs:tail
        jne     @@bufferIsNotFull
        mov     cs:head, ax
@@bufferIsNotFull:
        pop     bx
        ret
ringBufferWrite endp

ringBufferRead proc near
        push    bx
        mov     bx, cs:tail
        cmp     bx, cs:head
        jne     @@bufferIsNotEmpty
        pop     bx
        stc
        ret
@@bufferIsNotEmpty:
        mov     al, byte ptr cs:[bx]
        inc     word ptr cs:tail
        cmp     word ptr cs:tail, offset bufferEnd
        jne     @@noTailResumption
        mov     word ptr cs:tail, offset buffer
@@noTailResumption:
        pop     bx
        clc
        ret
ringBufferRead endp

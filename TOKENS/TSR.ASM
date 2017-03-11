; #############################################################################

oldHandlerPtr dd ?
tsrFunction db ?
tsrSubfunction = 42h
tsrMagicNumber = 0DEADh

; #############################################################################

tsrEntry:
        cmp     ah, cs:[tsrFunction]    ; check, that this resident was called
        jne     tsrRefuse               ; call next handler in chain if not

        cmp     al, 00h                 ; if al = 0 return 0FFh
        je      tsrReturn

        cmp     al, tsrSubfunction      ; else if al = tsrSubfunction
        jne     tsrRefuse

        cmp     dx, tsrMagicNumber      ; and dx = tsrMagicNumber
        jne     tsrRefuse

        push    cx
        mov     cx, 8
        ror     dx, cl                  ; swap bytes in DX
        pop     cx

tsrReturn:
        mov     al, 0FFh                ; "Hey, I'm here!"
        iret

tsrRefuse:     ; call next handler in chain
        jmp     cs:[oldHandlerPtr]

tsrCodeEnd:

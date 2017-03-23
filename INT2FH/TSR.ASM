; #############################################################################

; Resident data:
oldHandlerPtr dd ?
tsrFunction db ?

; Resident constants:
tsrMagicNumber = 0DEADh
tsrExpectedResponse = 0ADDEh
tsrPositiveResponse = 0FFh

; Resident subfunctions:
tsrCheck = 00h
tsrIdentify = 42h
tsrGetSegmentAddress = 80h

; #############################################################################

tsrEntry:
        cmp     ah, cs:[tsrFunction]    ; check, that this resident was called
        jne     tsrRefuse               ; call next handler in chain if not

        cmp     al, tsrCheck
        je      tsrDoCheck

        cmp     al, tsrIdentify
        je      tsrDoIdentify

        cmp     al, tsrGetSegmentAddress
        je      tsrDoGetSegmentAddress

        jmp     tsrRefuse

tsrDoCheck:
        mov     al, tsrPositiveResponse     ; "Hey, I'm here!"
        jmp     tsrReturn

tsrDoIdentify:
        cmp     dx, tsrMagicNumber          ; and dx = tsrMagicNumber
        jne     tsrRefuse

        push    cx
        mov     cx, 8
        ror     dx, cl                      ; swap bytes in DX
        pop     cx
        jmp     tsrReturn

tsrDoGetSegmentAddress:
        mov     ax, cs
        mov     es, ax

tsrReturn:
        iret

tsrRefuse:
        jmp     cs:[oldHandlerPtr]          ; call next handler in chain

tsrCodeEnd:

; #############################################################################

; #############################################################################

environVarsPtrOffset = 2Ch
multiplexInterruptNo = 2Fh
tsrExpectedResponse = 0ADDEh

; ## Init #####################################################################

tryInstallTsr proc c near uses ax bx cx dx si di
        arg @@tsrInstall21h:word ; 1 for int 21h, 0 for int 27h

        call    findInstalledTsr
        test    ax, ax
        jnz     tsrInstalledError
        call    selectFreeId
        test    ax, ax
        jz      noFreeIdError
        mov     cs:[tsrFunction], ah
        call    setInterruptVector

        lea     dx, [tsrSuccessMsg]
        mov     ah, 09h
        int     21h

        call    freeSystemMemory

        mov     ax, [@@tsrInstall21h]
        test    ax, ax
        jz      @@install27h

@@install21h:
        call    installTsr21h
        jmp     @@finish

@@install27h:
        call    installTsr27h
        jmp     @@finish

tsrInstalledError:
        lea     dx, [tsrInstalledErrorMsg]
        jmp     tsrErrorFinish
tsrInstalledErrorMsg db "Resident has already been installed.", 0Ah, 24h

noFreeIdError:
        lea     dx, [noFreeIdErrorMsg]
        jmp     tsrErrorFinish
noFreeIdErrorMsg db "No free ID was found for interrupt handler.", 0Ah, 24h

tsrErrorFinish:
        mov     ah, 09h
        int     21h
        int     20h

@@finish:
        ret

tryInstallTsr endp


findInstalledTsr:
        ; checks if tsr from this file was already installed earlier
        ; returns: ah = ID if already installed, ah = 0 otherwise
        mov     cx, 0FFh
@@checkLoop:
        xor     ax, ax
        mov     ah, cl
        mov     al, tsrIdentify
        mov     dx, tsrMagicNumber
        int     multiplexInterruptNo
        cmp     dx, tsrExpectedResponse
        jnz     @@checkLoopEnd
        ret
@@checkLoopEnd:
        dec     cx
        jnz     @@checkLoop         ; while cx != 0
        xor     ax, ax              ; if there is no response, return 0
        ret


selectFreeId:
        ; returns: ah = ID, if ID is found, ah = 0 otherwise
        mov     cx, 0FFh
@@selectIdLoop:
        xor     ax, ax              ; loop over all IDs
        mov     ah, cl
        int     multiplexInterruptNo
        test    al, al              ; if ok to install (al = 0), return this id
        jz      @@selectIdFinish
        dec     cx
        jnz     @@selectIdLoop
        xor     ax, ax              ; if not ok for all, return 0
@@selectIdFinish:
        ret


setInterruptVector:
        mov     ah, 35h
        mov     al, multiplexInterruptNo
        int     21h                             ; get int vector in es:bx
        mov     word ptr cs:[oldHandlerPtr], bx
        mov     word ptr cs:[oldHandlerPtr+2], es

        push    bx                              ; print old vector
        push    es
        lea     dx, [oldVectorMsg]
        mov     ah, 09h
        int     21h
        call    printSegmentOffset
        add     sp, 2 + 2

        lea     dx, [tsrEntry]
        mov     ah, 25h
        mov     al, multiplexInterruptNo
        int     21h                             ; set int vector to ds:dx

        push    dx                              ; print new vector
        push    ds
        lea     dx, [newVectorMsg]
        mov     ah, 09h
        int     21h
        call    printSegmentOffset
        add     sp, 2 + 2

        ret


oldVectorMsg db "Old interrupt vector: ", 24h
newVectorMsg db "New interrupt vector: ", 24h


freeSystemMemory:
        mov     dx, cs:[environVarsPtrOffset]
        mov     es, dx
        mov     ah, 49h
        int     21h
        ret


installTsr27h:
        lea     dx, [tsrCodeEnd]
        int     27h


installTsr21h:
        lea     dx, [tsrCodeEnd]

        mov     cl, 04h             ; divide by 16 = 2**4
        shr     dx, cl
        inc     dx

        mov     ax, 3100h
        int     21h


tsrSuccessMsg db "Resident successfully installed. Interrupt vector changed.", 0Ah, 24h


uninstallTsr proc c near uses ax bx cx dx es ds si di
        arg @@checkUninstallAvailable:word, @@allowResize:word

        call    findInstalledTsr
        test    ax, ax
        jz      @@tsrNotInstalledError

        mov     cs:[tsrFunction], ah

        call    loadTsrSegmentAddressToEs

        mov     ax, [@@checkUninstallAvailable]
        mov     bx, [@@allowResize]
        or      ax, bx
        test    ax, ax
        jz      @@uninstallCompletely

        call    isAbleToUninstallCompletely
        test    ax, ax
        jnz     @@uninstallCompletely

        mov     ax, [@@allowResize]
        test    ax, ax
        jz      @@uninstallNotAvailableError

@@resize:
        call    shrinkTsr
        jmp     @@finish

@@uninstallCompletely:
        call    uninstallTsrCompletely
        jmp     @@finish

@@tsrNotInstalledError:
        lea     dx, [@@tsrNotInstalledMessage]
        jmp     @@errorFinish
@@tsrNotInstalledMessage db "Resident is not installed, nothing to do.", 0Ah, 24h

@@uninstallNotAvailableError:
        lea     dx, [@@uninstallNotAvailableMsg]
        jmp     @@errorFinish
@@uninstallNotAvailableMsg db "Unable to uninstall resident, try REMOVE HARD or RESIZE.", 0Ah, 24h

@@errorFinish:
        mov     ah, 09h
        int     21h
        int     20h

@@finish:
        ret

uninstallTsr endp


uninstallTsrCompletely:
        ; assume that es is pointing to the segment with resident code

        push    ds

        lds     dx, es:[oldHandlerPtr]          ; load address of old handler
        mov     ah, 25h
        mov     al, multiplexInterruptNo
        int     21h                             ; set int vector to ds:dx
        mov     ax, ds
        pop     ds

        push    dx                              ; print old vector
        push    ax
        lea     dx, [oldVectorMsg]
        mov     ah, 09h
        int     21h
        call    printSegmentOffset
        add     sp, 2 + 2

        mov     ah, 49h
        int     21h             ; free resident memory block

        lea     dx, [uninstallCompletelyMsg]
        mov     ah, 09h
        int     21h

        ret

uninstallCompletelyMsg db "Resident is completely uninstalled. Interrupt vector is restored.", 0Ah, 24h


shrinkTsr:
        ; assume that es is pointing to the segment with resident code

        lea     si, [tsrRefuse]     ; address of JMP instruction
        lea     cx, [tsrCodeEnd]
        sub     cx, si              ; length of JMP instruction

        lea     di, [tsrEntry]

        push    cx
        rep     movsb               ; copy JMP to [tsrEntry]
        pop     cx

        lea     bx, [tsrEntry]
        add     bx, cx              ; new size of resident in bytes

        mov     cl, 04h             ; divide by 16 = 2**4
        shr     bx, cl
        inc     bx                  ; new size of resident in paragraphs

        mov     ah, 4Ah             ; resize resident block
        int     21h

        jc      @@shrinkError

        lea     dx, [shrinkMessage]
        mov     ah, 09h
        int     21h

        ret

@@shrinkError:
        lea     dx, [shrinkErrorMessage]
        mov     ah, 09h
        int     21h
        int     20h

shrinkMessage db "Resident has been shrinked. Interrupt vector is not changed.", 0Ah, 24h


shrinkErrorMessage db "Error resizing resident.", 0Ah, 24h


loadTsrSegmentAddressToEs:

        mov     ah, cs:[tsrFunction]
        mov     al, tsrGetSegmentAddress
        int     multiplexInterruptNo

        ret


isAbleToUninstallCompletely:

        ; args: es - segment address of resident

        push    es

        mov     ah, 35h
        mov     al, multiplexInterruptNo
        int     21h                         ; load vector in es:bx

        mov     bx, es
        pop     es
        mov     ax, es
        cmp     ax, bx

        jne     @@returnFalse

        mov     ax, 1
        ret

@@returnFalse:
        xor     ax, ax
        ret

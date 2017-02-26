    .model tiny
    .code
    org 100h

start:

    mov     ah, 49h
    mov     es, cs:[2Ch]
    int     21h                 ; free memory at cs:[2Ch]
    jc      free_error

    mov     ah, 48h
    mov     bx, 5
    int     21h                 ; allocate five paragraphs
    jc      alloc_error

    mov     es, ax              ; offset of that paragraphs
    mov     cs:[2Ch], ax

    mov     cx, buffer_length   ; fill allocated paragraphs
    mov     si, offset buffer   ; (copy cx bytes
    mov     di, 0               ; from ds:[si] to es:[di])
    rep     movsb

make_resident:
    mov     dx, 8               ; reserve 8 * 16 bytes for PSP
    mov     ax, 3100h           ; make TSR (al - return code)
    int     21h

alloc_error:
    mov     dx, offset alloc_error_msg
    jmp     error_end
alloc_error_msg     db  "Alloc error!$"

free_error:
    mov     dx, offset free_error_msg
    jmp     error_end
free_error_msg      db  "Free error!$"

error_end:
    mov     ah, 9
    int     21h
    int     20h

buffer  db  20h, 00h, 00h, 01h, 00h, "hack3r", 69 dup(0)
buffer_length = $ - buffer

end start

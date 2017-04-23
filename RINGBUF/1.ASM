.model tiny
locals

.code
        org     100h

start:
        jmp     begin

buflen  equ     20
buffer  db      buflen dup (0)
endbuf  equ     $
head    dw      offset buffer
tail    dw      offset buffer

write_buf proc near
        push    bx
        mov     bx, cs:head
        mov     byte ptr cs:[bx], al
        mov     ax, cs:head
        mov     ax, cs:head
        inc     word ptr cs:head
        cmp     word ptr cs:head, offset endbuf
        jne     @@1
        mov     cs:head, offset buffer
@@1:
        mov     bx, cs:head
        cmp     bx, cs:tail
        jnz     @@2
        mov     cs:head, ax
@@2:
        pop     bx
        ret
write_buf endp

read_buf proc near
        push    bx
        mov     bx, cs:tail
        cmp     bx, cs:head
        jnz     @@1
        pop     bx
        stc
        ret
@@1:
        mov     al, byte ptr cs:[bx]
        inc     word ptr cs:tail
        cmp     word ptr cs:tail, offset endbuf
        jnz     @@2
        mov     word ptr cs:tail, offset buffer
@@2:
        pop     bx
        clc
        ret
read_buf endp

command:        ; конвертирует сканкод в код команды
        db      01h,    5       ; exit
        db      50h,    1       ; up
        db      4Dh,    2       ; right
        db      4Bh,    3       ; left
        db      48h,    4       ; down
        db      0FFh,   0FFh    ; EOT

handler:        ; смещения обработчиков для каждой команды
        dw      1,      offset exit
;        dw      5,      offset exit
;        dw      1,      offset f_up
;        dw      2,      offset f_right
;        dw      3,      offset f_left
;        dw      4,      offset f_down
        dw      0FFFFh

old9:
old9segment     dw      0
old9offset      dw      0

begin proc near
        mov     ax, 3509h           ; сохраняем старый обработчик
        int     21h
        mov     di, offset old9
        mov     ax, es
        push    cs
        pop     es
        stosw
        mov     ax, bx
        stosw
        mov     dx, offset int9     ; устанавлиаем обработчик
        mov     ax, 2509h
        int     21h
@@1:
        hlt     ; ждем, пока не произойдет аппаратное прерывание
        call    read_buf
        jc      @@1
        mov     si, offset handler
        xor     ah, ah
        mov     bx, ax
@@2:
        lodsw
        cmp     ax, 0FFFFh
        jz      @@1
        cmp     ax, bx
        jz      @@3
        add     si, 2
        jmp     @@2
@@3:
        lodsw
        call    ax
        jmp     @@1
        ret
begin endp

int9 proc near
        push    ax
        in      al, 60h
        call    write_buf
        in      al, 61h
        or      al, 80h
        out     61h, al
        and     al, 7Fh
        out     61h, al
        mov     al, 20h
        out     20h, al
        pop     ax
        iret
int9 endp

tst    db  "exit", 24h

exit proc near

        mov     ah, 09h
        lea     dx, [tst]
        int     21h

        mov     dx, word ptr cs:[old9+2]
        mov     bx, word ptr cs:[old9]
        mov     ds, bx
        mov     ax, 2509h
        int     21h
        push    cs
        pop     ds
        int     20h
exit endp

end start

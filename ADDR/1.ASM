; 1. регистровая адресация
; intel:
    mov     ax, cx
; AT&T:
    mov     %cx, %ax

; 2. непосредственная адресация
; intel:
    mov     cx, 4
; AT&T:
    mov     $4, %ax
    mov     $m1, %ax

; 3. прямая адресация
m1:
; intel:
    mov     si, ds:[100h]
    mov     ax, m1
; AT&T:
    mov     m1, %ax
    mov     0x100, %ax

; 4. косвенная адресация
; intel:
    mov     ax, [si]
; AT&T:
    mov     (%rsi), %ax

; 5. по базе со сдвигом
; intel:
    mov     ax, [bp+2]
    mov     ax, [bp]+2
    mov     ax, 2[bp]
; AT&T:
    mov     2(%rbp), %ax

; 6. косвенная с масштабированием
; intel:
    mov     ax, 4[esi*2]
    mov     ax, [esi*2]+4
; AT&T:
    mov     2(,%rbp,4), %ax

; 7. по базе с индексированием
; intel:
    mov     ax, [bx+si+2]
; AT&T:
    mov     2(%rbx,%rsi,), %ax

; 8. по базе с индексированием и масштабированием
; intel:
    mov     ax, 2[ebx+ebp*4]
    mov     ax, [ebx+ebp*4]+2
; AT&T:
    mov     2(%rbx,%rbp,4), %ax

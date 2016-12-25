init_vga_mode macro
    mov     ax, 13h     ; AH=0 - Change video mode
    int     10h         ; AL=13h - Mode

    mov     ax, 0A000h
    mov     es, ax      ; ES points to video memory
endm


init_text_mode macro
    mov     ax, 3h
    int     10h

    xor     ax, ax
    mov     es, ax      ; clear ES
endm


gchar macro
    mov     ah, 07h
    int     21h
endm


ppixel macro row, column, color

ife row eq ax
    mov     ax, row
endif

ife column eq bx
    mov     bx, column
endif

    mov     dx, vga_width
    mul     dx
    add     bx, ax
    mov     byte ptr [es:bx], color
endm


rcursor macro
    mov     dh, 0
    mov     dl, 0
    call    set_cursor
endm


scursor macro row, column

ife row eq dh
    mov     dh, row
endif

ife column eq dl
    mov     dl, column
endif

    mov     ah, 02h
    xor     bh, bh
    int     10h
endm


pchar macro char, color

ife char eq al
    mov     al, char
endif

ife color eq bl
    mov     bl, color
endif

    mov     ah, 0eh
    int     10h
endm

vga_width = 320
vga_height = 200
char_width = 8
char_height = 8

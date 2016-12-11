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

vga_width = 320
vga_height = 200
char_width = 8
char_height = 8

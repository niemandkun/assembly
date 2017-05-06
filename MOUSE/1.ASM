        model   small
        locals

.stack

text segment
        assume  cs:text, ds:text, es:text

start:
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        ; set 10h video mode
        mov     ax, 13h
        int     10h

        ; reset mouse state
        xor     ax, ax
        int     33h

        ; show mouse pointer
        ;mov     ax, 1
        ;int     33h

        ; draw initial scene
        call    draw_scene

        ; set user-defined callback for mouse events
        ; CX = user interrupt mask

        ; |F-5|4|3|2|1|0| user interrupt mask in CX
        ;   |  | | | | `--- cursor position changed
        ;   |  | | | `---- left button pressed
        ;   |  | | `----- left button released
        ;   |  | `------ right button pressed
        ;   |  `------- right button released
        ;   `--------- unused

        mov     cx, 01h
        lea     dx, [handle_mouse]
        mov     ax, 0ch
        int     33h

        ; wait any key
        xor     ax, ax
        int     16h

        ; reset mouse again to delete callback
        xor     ax, ax
        int     33h

        ; reset video mode back to normal
        mov     ax, 03h
        int     10h

        ; exit
        mov     ah, 4ch
        int     21h

handle_mouse    proc
        ; AX = condition mask causing call
        ; CX = horizontal cursor position
        ; DX = vertical cursor position
        ; DI = horizontal counts
        ; SI = vertical counts
        ; DS = mouse driver data segment
        ; BX = button state:
        ;
        ;    |F-2|1|0|
        ;      |  | `--- left button (1 = pressed)
        ;      |  `---- right button (1 = pressed)
        ;      `------ unused
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        push    bx

        mov     ax, cx
        sub     ax, old_pos_x
        mov     old_pos_x, cx

        mov     bx, dx
        sub     bx, old_pos_y
        mov     old_pos_y, dx

        pop     cx

        test    cx, 1
        jnz     @@move_frame

        call    move_circle
        jmp     @@finish

@@move_frame:
        call    move_frame

@@finish:
        call    draw_scene
        retf
handle_mouse    endp

old_pos_x       dw      0
old_pos_y       dw      0

text ends

include model.asm
include print.asm
include graphics.asm

end start

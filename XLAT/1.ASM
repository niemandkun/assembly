.model tiny
locals

argc = 80h
argv = 81h

.code
    org 100h
start:
    xor     dx, dx          ; current state = 0
    mov     si, argv        ; source string
    mov     cl, ds:[argc]

loop_start:
    lodsb

    mov     bx, offset alphabet
    xlat    ; get in-alphabet code of character in al

    mov     di, dx
    shl     di, 1
    mov     bx, word ptr [states+di]
    xlat    ; get next state in al

    mov     dl, al

    dec     cl
    jg      loop_start

    cmp     dl, 16
    jne     mismatch

match:
    mov     dx, offset message_match
    jmp     print

mismatch:
    mov     dx, offset message_mismatch

print:
    mov     al, 0
    mov     ah, 9h
    int     21h

finish:
    ret

.data

message_match: db 'match', 0Dh, 0Ah, '$'
message_mismatch: db 'mismatch', 0Dh, 0Ah, '$'

; hydrogen dioxide

alphabet:   db  32  dup(0)
            db  1   ;space
            db  64  dup(0)
            db  3   dup(0) ;a - c
            db  2   ;d
            db  3   ;e
            db  0   ;f
            db  4   ;g
            db  5   ;h
            db  6   ;i
            db  4   dup(0) ;j - m
            db  7   ;n
            db  8   ;o
            db  2   dup(0) ;p - q
            db  9   ;r
            db  5   dup(0) ;s - w
            db  10  ;x
            db  11  ;y
            db  134 dup(0) ;z and other characters

; alphabet size is 12

state0:     db  5 dup(0),   01h,    6 dup(0)  ; h, initial state
state1:     db 11 dup(0),   02h               ; y
state2:     db  2 dup(0),   03h,    9 dup(0)  ; d
state3:     db  9 dup(0),   04h,    2 dup(0)  ; r
state4:     db  8 dup(0),   05h,    3 dup(0)  ; o
state5:     db  4 dup(0),   06h,    7 dup(0)  ; g
state6:     db  3 dup(0),   07h,    8 dup(0)  ; e
state7:     db  7 dup(0),   08h,    4 dup(0)  ; n
state8:     db  0,          09h,   10 dup(0)  ; space
state9:     db  2 dup(0),   0Ah,    9 dup(0)  ; d
stateA:     db  6 dup(0),   0Bh,    5 dup(0)  ; i
stateB:     db  8 dup(0),   0Ch,    3 dup(0)  ; o
stateC:     db 10 dup(0),   0Dh,    0         ; x
stateD:     db  6 dup(0),   0Eh,    5 dup(0)  ; i
stateE:     db  2 dup(0),   0Fh,    9 dup(0)  ; d
stateF:     db  3 dup(0),   10h,    8 dup(0)  ; e
state10:    db 12 dup(10h)                    ; match

states:     dw  state0, state1, state2, state3, state4, state5,\
                state6, state7, state8, state9, stateA, stateB,\
                stateC, stateD, stateE, stateF, state10

end start

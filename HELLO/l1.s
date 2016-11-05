.global _start
.text
_start:
    mov     $msg, %rsi
    mov     %rsi, %rdi

1:
    lodsb
    cmp     $0x21, %al
    jz      5f
    cmp     $0x61, %al
    jb      2f
    cmp     $0x7a, %al
    ja      2f
    sub     $0x20, %al

2:
    stosb
    jmp     1b

5:
    mov     $4, %eax
    mov     $1, %ebx
    mov     $msg, %ecx
    mov     $len, %edx
    int     $0x80

    mov     $1, %eax
    mov     $1, %ebx
    int     $0x80

.data
msg:    .ascii "hello, world!\n"
len = . - msg

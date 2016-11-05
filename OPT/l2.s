.global _start
.text

_start:
    mov     $0x3ffffffff, %rcx
1:
    nop
    nop
    nop
#   loop    1b
    decq    %rcx
    jnz     1b
    mov     $60, %rax
    syscall

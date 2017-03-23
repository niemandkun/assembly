.global _start
.text

_start:
    mov     $0x3, %rcx

1:
    pushq   %rcx
    movq    $0xffff, %rcx

2:
    pushq   %rcx
    movq    $0xffff, %rcx

3:
    nop
    nop
    nop

    decq    %rcx
    jnz     3b

    popq    %rcx
    decq    %rcx
    jnz     2b

    popq    %rcx
    decq    %rcx
    jnz     1b

    mov     $60, %rax
    syscall

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

    loop    3b

    popq    %rcx
    loop    2b

    popq    %rcx
    loop    1b

    mov     $60, %rax
    syscall

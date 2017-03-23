.global _start
.text

_start:
    popq    %r12

1:
    popq    %rsi
    pushq   %rsi
    callq   strlen
    popq    %rsi

    movq    $1, %rdi
    movq    $1, %rax
    syscall

    decq    %r12
    jnz     1b

    mov     $60, %rax
    syscall

strlen:
    # in:   %rdi - address of string
    # out:  %rdx - length of string
    xorq    %rdx, %rdx
1:
    lodsb
    test    %al, %al
    jz      1f
    inc     %rdx
    jmp     1b
1:
    retq

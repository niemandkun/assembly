.global _start

.data
dec:    .ascii "dec: "
dec_len = . - dec

hex:    .ascii "hex: "
hex_len = . - hex

.text

_start:
    movq    $hex, %rsi
    movq    $hex_len, %rdx
    call    print

    movq    $_start, %rax
    movq    $16, %rbx
    call    printf
    call    endl

    movq    $dec, %rsi
    movq    $dec_len, %rdx
    call    print

    movq    $_start, %rax
    movq    $10, %rbx
    call    printf
    call    endl

    call    exit


endl:
    # print EOL
    mov     $0xA, %dx
    push    %dx
    mov     %rsp, %rsi
    movq    $1, %rdx
    call    print
    pop     %dx
    ret


printf:
    # print number
    # rax -- number to print
    # rbx -- radix

    mov     %rsp, %rbp
    xor     %rcx, %rcx

push_loop:
    xor     %rdx, %rdx
    div     %rbx

    cmp     $0xA, %dx
    jl      decimal_number

hex_number:
    add     $0x7, %dx

decimal_number:
    add     $0x30, %dx

    push    %dx

    add     $2, %rcx
    test    %rax, %rax
    jg      push_loop

    mov     %rsp, %rsi
    movq    %rcx, %rdx
    call    print

    mov     %rbp, %rsp

    ret


print:
    # print any string from memory
    # rsi - offset, rdx - length
    movl    $1, %eax        # write
    movl    $1, %edi        # stdout
    syscall
    ret


exit:
    # make exit syscall
    movl    $60, %eax
    movl    $0, %edi
    syscall

.nolist
.macro printf addr len=5
    movq    $1, %rax
    movq    $1, %rdi
    movq    $\addr, %rsi
    movq    $\len, %rdx
    syscall
.endm

.macro fuck_humanity error_code=0
    movq    $\error_code, %rdi
    movq    $60, %rax
    syscall
.endm

.macro superprintf msg
.data
__m1 = .
    .ascii "\msg"
__m1len = . - __m1
.text
    printf __m1, __m1len
.endm
.list

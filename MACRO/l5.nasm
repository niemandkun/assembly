global _start

%macro  exit 1
    mov     eax, 1
    mov     ebx, %1
    int     0x80
%endmacro

%macro print 2
    mov     eax, 4
    mov     ebx, 1
    mov     ecx, %1
    mov     edx, %2
    int     0x80
%endmacro

%macro clear 2
    mov     edi, %1
    mov     ecx, %2
    xor     eax, eax
    cld
    rep     stosb
%endmacro

section .data
buffer:     resb 5
.len:       equ $ - buffer

section .text
_start:
    clear   buffer, buffer.len
    mov     dword [buffer], 'TEST'
    mov     byte [edi-1], 0xa
    print   buffer, buffer.len
    exit    0

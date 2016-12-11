format PE GUI 5.0 DLL at 0
entry DllEntryPoint

include 'win32a.inc'

section '.text' code readable executable

proc DllEntryPoint hinstDLL,fdwReason,lpvReserved
	mov   eax, TRUE
	ret
endp

proc Divide a, b
  push  ebx
  push  edx
  xor   edx, edx
  mov   eax, [a]
  mov   ebx, [b]
  div   ebx
  pop   edx
  pop   ebx
  ret
endp

proc Multiply a, b
  push  ebx  
  mov   eax, [a]
  mov   ebx, [b]
  mul   ebx
  pop   ebx
  ret
endp

proc Factorial n
  push  ebx
  push  ecx
  push  edx
  mov   ecx, [n]
  test  ecx, ecx
  jnz   @@1   
  mov   eax, 1    
  jmp   @@2
@@1:
  push  ecx    
  dec   ecx
  stdcall Factorial, ecx
  pop   ecx
  mul   ecx       
@@2:  
  pop   edx
  pop   ecx
  pop   ebx
  ret
endp

mov eax, Factorial  ; force relocation

section '.edata' export data readable

  export 'PROJECT.DLL',\
   Multiply,'Multiply',\
   Divide,'Divide',\
   Factorial,'Factorial'

section '.reloc' fixups data readable discardable
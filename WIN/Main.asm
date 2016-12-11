format PE GUI 4.0
entry Start

include 'win32a.inc'

section '.text' code readable executable

Start:
  invoke GetModuleHandle, 0
  mov [wc.hInstance], eax
  invoke LoadIcon, 0, IDI_APPLICATION
  mov [wc.hIcon], eax
  invoke  LoadCursor, 0, IDC_ARROW                    
  mov [wc.hCursor], eax
  invoke RegisterClass, wc                            
  test eax, eax
  jz error

  invoke CreateWindowEx, 0, _winclass, _wintitle,\ 
                         WS_VISIBLE + WS_DLGFRAME + WS_SYSMENU,\
                         128, 128, 256, 192, NULL, NULL, [wc.hInstance], NULL
  test eax, eax
  jz error
  mov [hWindow], eax
                         
  invoke CreateWindowEx, 0, _btnclass, _btntitle,\
                         WS_TABSTOP + WS_VISIBLE + WS_CHILD + BS_DEFPUSHBUTTON,\
                         10, 10, 100, 24, [hWindow], NULL, [wc.hInstance], NULL                         
  test eax, eax
  jz error
  mov [hButton], eax

msg_loop:
  invoke GetMessage, msg, NULL, 0, 0
  cmp eax, 1
  jb end_loop
  jne msg_loop
  invoke TranslateMessage, msg
  invoke DispatchMessage, msg
  jmp msg_loop

error:
  invoke MessageBox, NULL, _error, NULL, MB_ICONERROR + MB_OK

end_loop:
  invoke ExitProcess, [msg.wParam]

proc WindowProc uses ebx esi edi, hwnd, wmsg, wparam, lparam
  cmp [wmsg], WM_DESTROY
  je .wmdestroy
  
  cmp [wmsg], WM_COMMAND
  je .btnclick
  
.defwndproc:
  invoke DefWindowProc, [hwnd], [wmsg], [wparam], [lparam]
  jmp .finish

.btnclick:
  stdcall Random, 0, 128
  xchg eax, esi
  
  stdcall Random, 0, 128
  xchg eax, edi
  
  invoke MoveWindow, [hButton], esi, edi, 100, 24, TRUE 
  
  stdcall Random, 100, 1000
  xchg eax, esi
  
  stdcall Random, 100, 600
  xchg eax, edi
  
  invoke MoveWindow, [hWindow], esi, edi, 256, 192, TRUE 
  jmp .finish
  
.wmdestroy:
  invoke PostQuitMessage,0
  xor eax, eax
  
.finish:
  ret
endp

proc Random uses ebx ecx edx, min, max 
  ; seed = (seed * LARGE_PRIME_1) % LARGE_PRIME_2
  ; return min + seed % (max - min)
  
  mov   eax, [randomSeed]
  
  xor   edx, edx
  mov   ebx, 370248451
  mul   ebx
  
  xor   edx, edx
  mov   ebx, 433494437
  div   ebx
  
  xchg  eax, edx
  mov   [randomSeed], eax
  
  mov   ebx, [min]
  mov   ecx, [max]
  sub   ecx, ebx
  xor   edx, edx
  div   ecx
  xchg  eax, edx
  add   eax, ebx
  
  ret
endp

section '.data' data readable writeable

  _winclass TCHAR 'FASMWIN32', 0
  _wintitle TCHAR 'Win32 program template', 0
  _error TCHAR 'Startup failed.', 0

  _btnclass TCHAR 'BUTTON', 0
  _btntitle TCHAR 'Press me!', 0

  wc WNDCLASS 0, WindowProc, 0, 0, NULL, NULL, NULL, COLOR_BTNFACE + 1, NULL, _winclass

  msg MSG
  hWindow  dd 0
  hButton  dd 0
  randomSeed dd 1337

section '.idata' import data readable writeable

  library kernel32, 'KERNEL32.DLL',\
	  user32, 'USER32.DLL'

  include 'api\kernel32.inc'
  include 'api\user32.inc'
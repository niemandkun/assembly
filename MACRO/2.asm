        model tiny
        .code
        org     100h
        locals
include 1.asm
start:
        sprintf "Hello Hello!"

        rpush a, b, c
        rpop c, b, a

        superpush <ax,bx,cx,dx>

        supermul 2
        supermul 4
        supermul 7
        supermul 5

purge supermul

        int     20h
end start

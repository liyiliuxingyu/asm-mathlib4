        bits 64
        global l_lvlProbeBa
        section .text
l_lvlProbeBa:
        movzx   eax, byte [rcx+8]
        shl     eax, 16
        movzx   edx, byte [rcx+16]
        shl     edx, 8
        or      eax, edx
        movzx   edx, byte [rcx+24]
        or      eax, edx
        lea     rax, [rax*2+1]
        ret

; lvl_ba.asm -- Lean 解释器的 FFI 包装：从 ByteArray 取节点（data 在 +24）
        bits 64
        global l_lvlEquivBa
        global lvl_equiv
%include "lvl_equiv.asm"

; lean_object* l_lvlEquivBa(lean_object* ba, lean_object* offA, lean_object* offB)
l_lvlEquivBa:
        lea     r9, [rcx+24]
        mov     [rel baseVal], r9
        mov     rax, rdx
        shr     rax, 1
        lea     rdx, [r9+rax]
        mov     rax, r8
        shr     rax, 1
        lea     rcx, [r9+rax]
        call    lvl_equiv
        movzx   eax, al
        lea     rax, [rax*2+1]
        ret

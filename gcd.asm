; gcd.asm  --  手写 x86-64 汇编
; 目标: 对照 Lean 4 / mathlib 中的 Nat.gcd
;   Lean:  def gcd (a b : Nat) : Nat := if b = 0 then a else gcd b (a % b)
; 唯一区别: Lean 的 Nat 是任意精度, 这里限制在无符号 64 位。
; 对 64 位输入不产生分歧: gcd(a,b) <= min(a,b) < 2^64, 结果必然可表示。
;
; x64 Windows 调用约定: rcx = a, rdx = b, 返回值 rax
; 汇编: nasm -f bin -o gcd.bin gcd.asm      (位置无关, 无重定位, 纯代码)

        bits 64
        section .text

gcd_u64:
        mov     rax, rcx        ; rax = a
        mov     rcx, rdx        ; rcx = b
.loop:
        test    rcx, rcx        ; b == 0 ?
        jz      .done
        xor     edx, edx        ; div 的被除数高 64 位清零 (否则 #DE)
        div     rcx             ; rax = a / b ,  rdx = a % b
        mov     rax, rcx        ; a <- b
        mov     rcx, rdx        ; b <- a % b
        jmp     .loop
.done:
        ret                     ; 返回 rax

; lean_lifecycle.asm -- Lean 4.36 的对象引用计数完整生命周期，手写 x86-64
; 对照: src/include/lean/lean.h:734-750 (inc/dec)
;       src/runtime/object.cpp:472 (lean_dec_ref_cold)
;
; 节点布局（测试用，仿 lean_object + 一个子指针）:
;   +0  int32  m_rc
;   +4  uint32 m_cs_sz/m_other/m_tag（必须原样保留）
;   +8  void*  child（子对象，可为 0）
;
; 约定: rcx = obj, rdx = free_cb（宿主提供的 lean_free_object/del_core 替身）

STICKY      equ 0x90000000          ; INT_MIN + 0x10000000
STICKY_DROP equ 0xA0000000          ; INT_MIN + 0x20000000

        bits 64
        section .text

; ---------------------------------------------------------------- lean_inc
lean_inc_asm:
        test    cl, 1
        jnz     .noop
        mov     eax, [rcx]
        test    eax, eax
        jg      .st
        cmp     eax, STICKY
        jbe     .noop
        lock sub dword [rcx], 1
        mov     eax, 2
        ret
.st:
        add     dword [rcx], 1
        xor     eax, eax
        ret
.noop:
        xor     eax, eax
        ret

; ---------------------------------------------------------------- lean_dec
lean_dec_asm:
        test    cl, 1
        jnz     .noop
        mov     eax, [rcx]
        cmp     eax, 1
        jle     .cold
        sub     dword [rcx], 1
        xor     eax, eax
        ret
.cold:
        test    eax, eax
        jz      .noop              ; rc == 0: persistent, 不释放
        jmp     lean_dec_ref_cold_asm
.noop:
        xor     eax, eax
        ret

; ------------------------------------------------- lean_dec_ref_cold
; if (rc != 1) { if (never_freed) return; if (fetch_add(1) != -1) return; }
; free(o)
lean_dec_ref_cold_asm:
        mov     eax, [rcx]
        cmp     eax, 1
        je      .free
        cmp     eax, STICKY_DROP   ; 无符号: persistent(0) 或 sticky
        jbe     .noop
        mov     eax, 1
        lock xadd dword [rcx], eax ; eax = 旧值, 内存 +1
        cmp     eax, -1
        jne     .noop
.free:
        mov     rax, rdx
        test    rax, rax
        jz      .noop
        jmp     rax                ; 尾调用 free_cb(o)，rcx 仍是 o
.noop:
        xor     eax, eax
        ret

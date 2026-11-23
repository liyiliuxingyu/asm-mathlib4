; lean_rc.asm -- Lean 4.36 运行时引用计数热路径，手写 x86-64
; 逐行对照: src/include/lean/lean.h:734-750 (lean_inc / lean_dec)
;           src/include/lean/lean.h:179-184 (对象布局)
;
; typedef struct { int m_rc; unsigned m_cs_sz:16; unsigned m_other:8; unsigned m_tag:8; } lean_object;
;   -> m_rc 在偏移 0 (4 字节), m_tag 在偏移 7
;
; 语义 (4.36 的新方案): m_rc > 0 单线程; == 0 持久化(不计数); < 0 多线程(计数为负)
;   溢出/下溢落进 sticky 区 [INT_MIN, INT_MIN+0x20000000) 后对象冻结
;
; 调用约定: rcx = lean_object*,  rax = 状态码
;   0 = 内联完成 / 无需调整
;   1 = dec 必须走 cold path (释放对象; 本 demo 不实现)
;   2 = inc 走了多线程原子路径

STICKY  equ 0x90000000          ; INT_MIN + 0x10000000

        bits 64
        section .text

lean_inc_asm:
        test    cl, 1           ; lean_is_scalar(o): 指针最低位为 1
        jnz     .noop
        mov     eax, [rcx]      ; lean_internal_get_rc
        test    eax, eax
        jg      .st             ; > 0: 单线程
        cmp     eax, STICKY     ; 无符号比较 == lean_is_unstuck_mt
        jbe     .noop           ; 0 = persistent, 或 sticky: 计数不动
        lock sub dword [rcx], 1 ; 多线程计数是负的, 所以 inc 反而减 1
        mov     eax, 2
        ret
.st:
        add     dword [rcx], 1  ; 无符号回绕, 溢出直接落进 sticky 区 (lean.h:420)
        xor     eax, eax
        ret
.noop:
        xor     eax, eax
        ret

lean_dec_asm:
        test    cl, 1           ; lean_is_scalar(o)
        jnz     .noop
        mov     eax, [rcx]
        cmp     eax, 1
        jle     .not_gt1        ; rc <= 1
        sub     dword [rcx], 1
        xor     eax, eax
        ret
.not_gt1:
        test    eax, eax
        jz      .noop           ; rc == 0: 持久化, 不释放
        mov     eax, 1          ; rc == 1 -> lean_dec_ref_cold; rc < 0 -> cold 处理 mt
        ret
.noop:
        xor     eax, eax
        ret

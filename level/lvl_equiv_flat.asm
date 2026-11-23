; lvl_equiv.asm -- level::is_equivalent 的归一化切片：zero / succ / param / max / imax
; 对照: src/kernel/level.cpp:478 is_equivalent, 414-476 normalize, 105-116 mk_imax, 149-161 is_not_zero
;       src/Lean/Level.lean:381-410 normalize / isEquiv（oracle）
;
; 覆盖: 叶子 zero/param；imax 的两个参数只允许 succ^k(param) 或 zero（不含嵌套 imax/max）
; 项布局 (40 字节): +0 kind(0=explicit,1=param,2=imax) +8 off +16 a +24 oa +32 b
;   explicit: off=k, a=0
;   param   : off=k, a=id+1
;   imax    : off=k, a=id1+1, oa=k1, b=id2+1   (右参数恒为 offset 0 的 param)

BUFSZ   equ 64
TERM    equ 40

        bits 64
        section .bss
        align 16
bufA:   resb BUFSZ*TERM
bufB:   resb BUFSZ*TERM
baseVal: resq 1

        section .text

; ---------------------------------------------------------------- emit helpers
; (inline, no calls)

; ---------------------------------------------------------------- canon
; rcx = level, rdx = buf, r8d = offset ; rax = next free slot
canon:
        push    rbx
        push    rdi
        push    r12
        push    r13
        push    r14
        mov     rbx, rcx
        mov     rdi, rdx
        mov     r12d, r8d
.strip:
        test    rbx, rbx
        jz      .zero
        cmp     dword [rbx], 2
        jne     .after
        mov     rbx, [rbx+8]
        add     rbx, [rel baseVal]
        inc     r12d
        jmp     .strip
.after:
        cmp     dword [rbx], 1
        je      .zero
        cmp     dword [rbx], 4
        je      .param
        cmp     dword [rbx], 3
        je      .max
        cmp     dword [rbx], 5
        je      .imax
        cmp     dword [rbx], 6
        je      .mvar
        jmp     .zero
.max:
        mov     rcx, [rbx+8]
        add     rcx, [rel baseVal]
        mov     rdx, rdi
        mov     r8d, r12d
        call    canon
        mov     rdi, rax
        mov     rcx, [rbx+16]
        add     rcx, [rel baseVal]
        mov     rdx, rdi
        mov     r8d, r12d
        call    canon
        mov     rdi, rax
        jmp     .done
.param:
        mov     eax, [rbx+8]
        inc     rax
        mov     qword [rdi], 1
        mov     [rdi+8], r12
        mov     [rdi+16], rax
        mov     qword [rdi+24], 0
        mov     qword [rdi+32], 0
        add     rdi, TERM
        jmp     .done
.mvar:
        mov     eax, [rbx+8]
        inc     rax
        mov     qword [rdi], 2
        mov     [rdi+8], r12
        mov     [rdi+16], rax
        mov     qword [rdi+24], 0
        mov     qword [rdi+32], 0
        add     rdi, TERM
        jmp     .done
.zero:
        mov     qword [rdi], 0
        mov     [rdi+8], r12
        mov     qword [rdi+16], 0
        mov     qword [rdi+24], 0
        mov     qword [rdi+32], 0
        add     rdi, TERM
        jmp     .done

; ---- imax: mk_imax(normalize l1, normalize l2) 之后再套 k 层 succ
.imax:
        mov     r13, [rbx+8]            ; l1
        add     r13, [rel baseVal]
        mov     r14, [rbx+16]           ; l2
        add     r14, [rel baseVal]
        ; 剥 l2 的 succ -> (r14, r9d=k2)
        xor     r9d, r9d
.strip2:
        test    r14, r14
        jz      .rhs_ready
        cmp     dword [r14], 2
        jne     .rhs_ready
        mov     r14, [r14+8]
        add     r14, [rel baseVal]
        inc     r9d
        jmp     .strip2
.rhs_ready:
        test    r9d, r9d
        jz      .rhs_maybe_zero         ; k2 == 0
        ; rhs 是 succ... -> is_not_zero -> imax 退化成 max，k 推进两边
        mov     rcx, r13
        mov     rdx, rdi
        mov     r8d, r12d
        call    canon
        mov     rdi, rax
        mov     rcx, [rbx+16]
        add     rcx, [rel baseVal]
        mov     rdx, rdi
        mov     r8d, r12d
        call    canon
        mov     rdi, rax
        jmp     .done
.rhs_maybe_zero:
        test    r14, r14
        jz      .imax_zero              ; rhs 就是 zero -> 结果 zero
        cmp     dword [r14], 1
        je      .imax_zero
        ; 剥 l1 -> (r13, r9d=k1)
        xor     r9d, r9d
.strip1:
        test    r13, r13
        jz      .lhs_ready
        cmp     dword [r13], 2
        jne     .lhs_ready
        mov     r13, [r13+8]
        add     r13, [rel baseVal]
        inc     r9d
        jmp     .strip1
.lhs_ready:
        test    r13, r13
        jz      .lhs_is_zero
        cmp     dword [r13], 1
        jne     .lhs_nonzero
.lhs_is_zero:
        cmp     r9d, 1                  ; imax 0 u = imax 1 u = u
        jbe     .emit_rhs
.lhs_nonzero:
        ; imax u u ?  (同 kind 同 id 且 k1 == 0)
        test    r9d, r9d
        jnz     .imax_atom
        mov     eax, [r13]
        cmp     eax, [r14]
        jne     .imax_atom
        mov     eax, [r13+8]
        cmp     eax, [r14+8]
        je      .emit_rhs               ; imax u u = u
.imax_atom:
        ; a = (lhsKind << 32) | (id1 + 1),  kind: 0=zero-base 1=param 2=mvar
        xor     eax, eax
        test    r13, r13
        jz      .lk_done
        mov     eax, [r13]
        cmp     eax, 4
        je      .lk_p
        cmp     eax, 6
        je      .lk_v
        xor     eax, eax
        jmp     .lk_done
.lk_p:
        mov     eax, 1
        jmp     .lk_done
.lk_v:
        mov     eax, 2
.lk_done:
        shl     rax, 32
        mov     edx, 1
        test    r13, r13
        jz      .id1_done
        mov     edx, [r13+8]
        inc     edx
.id1_done:
        or      rax, rdx
        mov     [rdi+16], rax
        mov     [rdi+24], r9
        ; b = (rhsKind << 32) | (id2 + 1)
        mov     eax, 1
        cmp     dword [r14], 6
        jne     .rk_done
        mov     eax, 2
.rk_done:
        shl     rax, 32
        mov     edx, [r14+8]
        inc     edx
        or      rax, rdx
        mov     [rdi+32], rax
        mov     qword [rdi], 3          ; kind = imax
        mov     [rdi+8], r12
        add     rdi, TERM
        jmp     .done
.emit_rhs:
        mov     qword [rdi], 1
        cmp     dword [r14], 6
        jne     .er_k
        mov     qword [rdi], 2
.er_k:
        mov     [rdi+8], r12
        mov     eax, [r14+8]
        inc     eax
        mov     [rdi+16], rax
        mov     qword [rdi+24], 0
        mov     qword [rdi+32], 0
        add     rdi, TERM
        jmp     .done
.imax_zero:
        mov     qword [rdi], 0
        mov     [rdi+8], r12
        mov     qword [rdi+16], 0
        mov     qword [rdi+24], 0
        mov     qword [rdi+32], 0
        add     rdi, TERM
.done:
        mov     rax, rdi
        pop     r14
        pop     r13
        pop     r12
        pop     rdi
        pop     rbx
        ret

; ---------------------------------------------------------------- sort
; rcx = base, rdx = end ; 按 (kind, a, oa, b, off) 升序
sort:
        push    rbx
        push    rsi
        push    rdi
        push    r13
        mov     rbx, rcx
        mov     rsi, rcx
        add     rsi, TERM
.loop_i:
        cmp     rsi, rdx
        jae     .done
        ; key = *rsi (5 qwords) -> r8..r12? use r8,r9,r10,r11,r13
        mov     r8,  [rsi]
        mov     r9,  [rsi+8]
        mov     r10, [rsi+16]
        mov     r11, [rsi+24]
        mov     r13, [rsi+32]
        mov     rcx, rsi
.loop_j:
        cmp     rcx, rbx
        jbe     .place
        ; compare key vs prev ([rcx-40])
        mov     rax, [rcx-TERM]
        cmp     rax, r8
        jb      .place
        ja      .shift
        mov     rax, [rcx-TERM+16]
        cmp     rax, r10
        jb      .place
        ja      .shift
        mov     rax, [rcx-TERM+24]
        cmp     rax, r11
        jb      .place
        ja      .shift
        mov     rax, [rcx-TERM+32]
        cmp     rax, r13
        jb      .place
        ja      .shift
        mov     rax, [rcx-TERM+8]
        cmp     rax, r9
        jbe     .place
.shift:
        mov     rax, [rcx-TERM]
        mov     [rcx], rax
        mov     rax, [rcx-TERM+8]
        mov     [rcx+8], rax
        mov     rax, [rcx-TERM+16]
        mov     [rcx+16], rax
        mov     rax, [rcx-TERM+24]
        mov     [rcx+24], rax
        mov     rax, [rcx-TERM+32]
        mov     [rcx+32], rax
        sub     rcx, TERM
        jmp     .loop_j
.place:
        mov     [rcx], r8
        mov     [rcx+8], r9
        mov     [rcx+16], r10
        mov     [rcx+24], r11
        mov     [rcx+32], r13
        add     rsi, TERM
        jmp     .loop_i
.done:
        pop     r13
        pop     rdi
        pop     rsi
        pop     rbx
        ret

; ---------------------------------------------------------------- dedupe
; rcx = base, rdx = end ; rax = new end（同 kind/a/oa/b 留最大 off）
dedupe:
        push    rsi
        push    rdi
        push    r13
        mov     rsi, rcx
        add     rsi, TERM
        mov     rdi, rcx
        cmp     rcx, rdx
        je      .empty
        ; cur = *rcx
        mov     r8, [rcx]
        mov     r9, [rcx+8]
        mov     r10, [rcx+16]
        mov     r11, [rcx+24]
        mov     r13, [rcx+32]
.next:
        cmp     rsi, rdx
        jae     .flush
        mov     rax, [rsi]
        cmp     rax, r8
        jne     .flush
        mov     rax, [rsi+16]
        cmp     rax, r10
        jne     .flush
        mov     rax, [rsi+24]
        cmp     rax, r11
        jne     .flush
        mov     rax, [rsi+32]
        cmp     rax, r13
        jne     .flush
        mov     r9, [rsi+8]
        add     rsi, TERM
        jmp     .next
.flush:
        mov     [rdi], r8
        mov     [rdi+8], r9
        mov     [rdi+16], r10
        mov     [rdi+24], r11
        mov     [rdi+32], r13
        add     rdi, TERM
        cmp     rsi, rdx
        jae     .ret
        mov     r8, [rsi]
        mov     r9, [rsi+8]
        mov     r10, [rsi+16]
        mov     r11, [rsi+24]
        mov     r13, [rsi+32]
        add     rsi, TERM
        jmp     .next
.empty:
        mov     rax, rcx
        pop     r13
        pop     rdi
        pop     rsi
        ret
.ret:
        mov     rax, rdi
        pop     r13
        pop     rdi
        pop     rsi
        ret

; ---------------------------------------------------------------- subsume
; rcx = base, rdx = end ; rax = new end（显式宇宙被更大的项吸收）
subsume:
        mov     rax, rdx
        mov     r8, rdx
        sub     r8, rcx
        cmp     r8, 2*TERM
        jb      .ret
        cmp     qword [rcx], 0
        jne     .ret
        mov     r9, [rcx+8]
        lea     r10, [rcx+TERM]
.scan:
        cmp     r10, rdx
        jae     .ret
        mov     r11, [r10+8]
        cmp     r11, r9
        jae     .drop
        add     r10, TERM
        jmp     .scan
.drop:
        lea     r8, [rcx+TERM]
        mov     r9, rcx
.shift:
        cmp     r8, rdx
        jae     .shift_done
        mov     r11, [r8]
        mov     [r9], r11
        mov     r11, [r8+8]
        mov     [r9+8], r11
        mov     r11, [r8+16]
        mov     [r9+16], r11
        mov     r11, [r8+24]
        mov     [r9+24], r11
        mov     r11, [r8+32]
        mov     [r9+32], r11
        add     r8, TERM
        add     r9, TERM
        jmp     .shift
.shift_done:
        mov     rax, rdx
        sub     rax, TERM
        ret
.ret:
        mov     rax, rdx
        ret

; ---------------------------------------------------------------- lvl_equiv
; rcx = a, rdx = b ; eax = 1/0
lvl_equiv:
        push    rbx
        push    r12
        push    r13
        mov     rbx, rdx
        lea     rdx, [rel bufA]
        xor     r8d, r8d
        call    canon
        mov     r12, rax
        mov     rcx, rbx
        lea     rdx, [rel bufB]
        xor     r8d, r8d
        call    canon
        mov     r13, rax
        lea     rcx, [rel bufA]
        mov     rdx, r12
        call    sort
        lea     rcx, [rel bufB]
        mov     rdx, r13
        call    sort
        lea     rcx, [rel bufA]
        mov     rdx, r12
        call    dedupe
        mov     r12, rax
        lea     rcx, [rel bufB]
        mov     rdx, r13
        call    dedupe
        mov     r13, rax
        lea     rcx, [rel bufA]
        mov     rdx, r12
        call    subsume
        mov     r12, rax
        lea     rcx, [rel bufB]
        mov     rdx, r13
        call    subsume
        mov     r13, rax
        lea     r8, [rel bufA]
        mov     rax, r12
        sub     rax, r8
        lea     r9, [rel bufB]
        mov     rdx, r13
        sub     rdx, r9
        cmp     rax, rdx
        jne     .no
        lea     rcx, [rel bufA]
        lea     rdx, [rel bufB]
.cmp_loop:
        cmp     rcx, r12
        jae     .yes
        mov     rax, [rcx]
        cmp     rax, [rdx]
        jne     .no
        mov     rax, [rcx+8]
        cmp     rax, [rdx+8]
        jne     .no
        mov     rax, [rcx+16]
        cmp     rax, [rdx+16]
        jne     .no
        mov     rax, [rcx+24]
        cmp     rax, [rdx+24]
        jne     .no
        mov     rax, [rcx+32]
        cmp     rax, [rdx+32]
        jne     .no
        add     rcx, TERM
        add     rdx, TERM
        jmp     .cmp_loop
.yes:
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     r13
        pop     r12
        pop     rbx
        ret

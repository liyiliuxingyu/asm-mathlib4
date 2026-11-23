; expr.asm -- Expr 结构相等（切片 v1）
; 节点 32 字节: tag | a | b | c | info
;  tag 1=bvar 2=fvar 3=mvar 4=const(无 levels) 5=app 6=lam 7=forallE 8=letE 9=lit(nat)
        bits 64
        section .bss
        align 16
ebase:  resq 1
        section .text
        global l_exprEqBa

eeq:
        push    rbx
        push    r12
        mov     rbx, rcx
        mov     r12, rdx
        mov     rax, [rbx]
        cmp     rax, [r12]
        jne     .no
        cmp     rax, 5
        je      .app
        cmp     rax, 6
        je      .binder
        cmp     rax, 7
        je      .binder
        cmp     rax, 8
        je      .let3
        cmp     rax, 4
        je      .const
        cmp     rax, 10
        je      .sort
        cmp     rax, 11
        je      .proj
        mov     rax, [rbx+8]
        cmp     rax, [r12+8]
        jne     .no
        mov     eax, 1
        jmp     .out
.app:
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    eeq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    eeq
        jmp     .out
.binder:
        mov     rax, [rbx+24]
        cmp     rax, [r12+24]
        jne     .no
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    eeq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    eeq
        jmp     .out
.let3:
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    eeq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    eeq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+24]
        add     rcx, [rel ebase]
        mov     rdx, [r12+24]
        add     rdx, [rel ebase]
        call    eeq
        jmp     .out
.const:
        mov     rax, [rbx+8]
        cmp     rax, [r12+8]
        jne     .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    leqList
        jmp     .out
.sort:
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    leq
        jmp     .out
.proj:
        mov     rax, [rbx+8]
        cmp     rax, [r12+8]
        jne     .no
        mov     rax, [rbx+16]
        cmp     rax, [r12+16]
        jne     .no
        mov     rcx, [rbx+24]
        add     rcx, [rel ebase]
        mov     rdx, [r12+24]
        add     rdx, [rel ebase]
        call    eeq
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- leqList
; rcx = 链表 A, rdx = 链表 B -> eax（30=cons 31=nil）
leqList:
        push    rbx
        push    r12
        mov     rbx, rcx
        mov     r12, rdx
        mov     rax, [rbx]
        cmp     rax, [r12]
        jne     .no
        cmp     rax, 31
        je      .yes
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    leq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    leqList
        jmp     .out
.yes:
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- leq（level 结构比较）
; rcx = level A, rdx = level B -> eax
leq:
        push    rbx
        push    r12
        mov     rbx, rcx
        mov     r12, rdx
        mov     rax, [rbx]
        cmp     rax, [r12]
        jne     .no
        cmp     rax, 20
        je      .yes
        cmp     rax, 22
        je      .two
        cmp     rax, 23
        je      .two
        ; 21=succ（一个孩子）, 24/25（id）
        cmp     rax, 21
        je      .one
        mov     rax, [rbx+8]
        cmp     rax, [r12+8]
        jne     .no
        jmp     .yes
.one:
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    leq
        jmp     .out
.two:
        mov     rcx, [rbx+8]
        add     rcx, [rel ebase]
        mov     rdx, [r12+8]
        add     rdx, [rel ebase]
        call    leq
        test    eax, eax
        jz      .no
        mov     rcx, [rbx+16]
        add     rcx, [rel ebase]
        mov     rdx, [r12+16]
        add     rdx, [rel ebase]
        call    leq
        jmp     .out
.yes:
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     r12
        pop     rbx
        ret

; lean_object* l_exprEqBa(ba, offA, offB)
l_exprEqBa:
        lea     r9, [rcx+24]
        mov     [rel ebase], r9
        mov     rax, rdx
        shr     rax, 1
        lea     rcx, [r9+rax]
        mov     rax, r8
        shr     rax, 1
        lea     rdx, [r9+rax]
        call    eeq
        movzx   eax, al
        lea     rax, [rax*2+1]
        ret
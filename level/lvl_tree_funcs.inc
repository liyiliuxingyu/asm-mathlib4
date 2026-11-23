; lvl_tree.asm -- level 归一化：支持 imax 参数为 max/imax（嵌套）
; 项 48 字节: kind|off|a|na|b|nb
;   atom:  kind 0/1/2, a=id+1
;   imax:  kind 3, a=lhs 列表起点, na=lhs 项数, b=rhs 列表起点, nb=rhs 项数
; max: 就是「项列表」本身（有序/去重/显式宇宙被吸收）

BUFSZ  equ 131072
TERM   equ 48

        bits 64
        section .bss
        align 16
bufA:   resb BUFSZ
bufB:   resb BUFSZ
baseVal: resq 1

        section .text

; ================================================================ cmpTerm
; rcx = 项A, rdx = 项B ; eax = -1 / 0 / 1
cmpTerm:
        push    rbx
        push    r12
        push    r13
        mov     rbx, rcx
        mov     r12, rdx
        mov     rax, [rbx]
        mov     r9, [r12]
        cmp     rax, r9
        jb      .lt
        ja      .gt
        cmp     rax, 3
        je      .imax
        mov     rax, [rbx+16]
        mov     r9, [r12+16]
        cmp     rax, r9
        jb      .lt
        ja      .gt
        jmp     .byoff
.imax:
        mov     rcx, [rbx+16]
        mov     rdx, [rbx+24]
        mov     r8, [r12+16]
        mov     r9, [r12+24]
        call    cmpList
        test    eax, eax
        jnz     .ret
        mov     rcx, [rbx+32]
        mov     rdx, [rbx+40]
        mov     r8, [r12+32]
        mov     r9, [r12+40]
        call    cmpList
        test    eax, eax
        jnz     .ret
.byoff:
        mov     rax, [rbx+8]
        mov     r9, [r12+8]
        cmp     rax, r9
        jb      .lt
        ja      .gt
        xor     eax, eax
        jmp     .ret
.lt:
        mov     eax, -1
        jmp     .ret
.gt:
        mov     eax, 1
.ret:
        pop     r13
        pop     r12
        pop     rbx
        ret

; ================================================================ cmpList
; rcx = A起, rdx = A数, r8 = B起, r9 = B数 ; eax = -1/0/1
cmpList:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rbx, rcx
        mov     r12, rdx
        mov     r13, r8
        mov     r14, r9
        xor     r15, r15
.loop:
        cmp     r15, r12
        jae     .a_end
        cmp     r15, r14
        jae     .gt                     ; A 更长
        imul    rax, r15, TERM
        lea     rcx, [rbx+rax]
        lea     rdx, [r13+rax]
        call    cmpTerm
        test    eax, eax
        jnz     .ret
        inc     r15
        jmp     .loop
.a_end:
        cmp     r12, r14
        jb      .lt
        ja      .gt
        xor     eax, eax
        jmp     .ret
.lt:
        mov     eax, -1
        jmp     .ret
.gt:
        mov     eax, 1
.ret:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ================================================================ sameKey
; rcx, rdx 两项；忽略 off 判断是否同一个键 ; eax = 1/0
sameKey:
        push    rbx
        push    r12
        mov     rbx, rcx
        mov     r12, rdx
        mov     rax, [rbx]
        cmp     rax, [r12]
        jne     .no
        cmp     rax, 3
        je      .imax
        mov     rax, [rbx+16]
        cmp     rax, [r12+16]
        jne     .no
        mov     eax, 1
        jmp     .ret
.imax:
        mov     rcx, [rbx+16]
        mov     rdx, [rbx+24]
        mov     r8, [r12+16]
        mov     r9, [r12+24]
        call    cmpList
        test    eax, eax
        jnz     .no
        mov     rcx, [rbx+32]
        mov     rdx, [rbx+40]
        mov     r8, [r12+32]
        mov     r9, [r12+40]
        call    cmpList
        test    eax, eax
        jnz     .no
        mov     eax, 1
        jmp     .ret
.no:
        xor     eax, eax
.ret:
        pop     r12
        pop     rbx
        ret

; ================================================================ copy48
; rcx = dst, rdx = src
copy48:
        mov     rax, [rdx]
        mov     [rcx], rax
        mov     rax, [rdx+8]
        mov     [rcx+8], rax
        mov     rax, [rdx+16]
        mov     [rcx+16], rax
        mov     rax, [rdx+24]
        mov     [rcx+24], rax
        mov     rax, [rdx+32]
        mov     [rcx+32], rax
        mov     rax, [rdx+40]
        mov     [rcx+40], rax
        ret

; ================================================================ sortList
; rcx = 起, rdx = 止（插入排序，用 cmpTerm）
sortList:
        push    rbx
        push    rsi
        push    rdi
        push    r13
        sub     rsp, 64
        mov     rbx, rcx
        lea     rsi, [rcx+TERM]
.loop_i:
        cmp     rsi, rdx
        jae     .done
        mov     rcx, rsp
        mov     rdx, rsi
        call    copy48                  ; 暂存当前项
        mov     rdi, rsi
.loop_j:
        cmp     rdi, rbx
        jbe     .place
        lea     rcx, [rdi-TERM]
        mov     rdx, rsp
        call    cmpTerm                 ; 前一项 vs 当前项
        cmp     eax, 0
        jle     .place
        mov     rcx, rdi
        lea     rdx, [rdi-TERM]
        call    copy48
        sub     rdi, TERM
        jmp     .loop_j
.place:
        mov     rcx, rdi
        mov     rdx, rsp
        call    copy48
        add     rsi, TERM
        jmp     .loop_i
.done:
        add     rsp, 64
        pop     r13
        pop     rdi
        pop     rsi
        pop     rbx
        ret

; ================================================================ dedupeList
; rcx = 起, rdx = 止 ; rax = 新止（同键保留 max off）
dedupeList:
        push    rbx
        push    r12
        push    r13
        push    r14
        mov     rbx, rcx                ; 读指针
        mov     r12, rdx
        mov     r13, rcx                ; 写指针
        cmp     rbx, r12
        je      .empty
.next:
        lea     r14, [rbx+TERM]         ; 候选
.scan:
        cmp     r14, r12
        jae     .flush
        mov     rcx, rbx
        mov     rdx, r14
        call    sameKey
        test    eax, eax
        jz      .flush
        ; 同键：保留 off 大的
        mov     rax, [r14+8]
        cmp     rax, [rbx+8]
        jbe     .skip
        mov     rcx, rbx
        mov     rdx, r14
        call    copy48
.skip:
        add     r14, TERM
        jmp     .scan
.flush:
        mov     rcx, r13
        mov     rdx, rbx
        call    copy48
        add     r13, TERM
        cmp     r14, r12
        jae     .done
        mov     rbx, r14
        jmp     .next
.empty:
        mov     rax, r13
        jmp     .ret
.done:
        mov     rax, r13
.ret:
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ================================================================ subsumeList
; rcx = 起, rdx = 止 ; rax = 新止
subsumeList:
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
        mov     r11, [r8+40]
        mov     [r9+40], r11
        add     r8, TERM
        add     r9, TERM
        jmp     .shift
.shift_done:
        mov     rax, rdx
        sub     rax, TERM
.ret:
        ret

; ================================================================ shiftList
; rcx = 起, rdx = 止, r8 = 目标, r9d = k ; rax = 新止
shiftList:
        push    rbx
        mov     rbx, r8
.loop:
        cmp     rcx, rdx
        jae     .done
        mov     rax, [rcx]
        mov     [rbx], rax
        mov     rax, [rcx+8]
        add     rax, r9
        mov     [rbx+8], rax
        mov     rax, [rcx+16]
        mov     [rbx+16], rax
        mov     rax, [rcx+24]
        mov     [rbx+24], rax
        mov     rax, [rcx+32]
        mov     [rbx+32], rax
        mov     rax, [rcx+40]
        mov     [rbx+40], rax
        add     rcx, TERM
        add     rbx, TERM
        jmp     .loop
.done:
        mov     rax, rbx
        pop     rbx
        ret

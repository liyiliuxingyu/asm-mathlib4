; lvl_tree2.asm -- 规范形式 = arena 里的连续项列表；父节点按地址收集/排序/去重/拷贝
; 项 48 字节: kind|off|a|na|b|nb
BUFSZ   equ 262144
TERM    equ 48
MAXD    equ 32
MAXTERM equ 256

        bits 64
        section .bss
        align 16
arena:      resb BUFSZ
arenaTop:   resq 1
depth:      resq 1
counts:     resq MAXD
scratch:    resb MAXD*MAXTERM*8
imaxArr:    resb MAXTERM*8
baseVal:    resq 1

        section .text

; ---------------------------------------------------------------- alloc
; rcx = 项数 -> rax = 指针
alloc:
        imul    rcx, rcx, TERM
        mov     rax, [rel arenaTop]
        lea     rdx, [rel arena]
        add     rdx, rax
        add     rax, rcx
        mov     [rel arenaTop], rax
        mov     rax, rdx
        ret

; ---------------------------------------------------------------- getArr
getArr:
        mov     rax, [rel depth]
        imul    rax, rax, MAXTERM*8
        lea     rcx, [rel scratch]
        add     rax, rcx
        ret

; ---------------------------------------------------------------- pushAddr
; rcx = 地址
pushAddr:
        mov     rdx, [rel depth]
        lea     r8, [rel counts]
        mov     r9, [r8+rdx*8]
        mov     r10, [rel depth]
        imul    r10, r10, MAXTERM*8
        lea     r11, [rel scratch]
        add     r11, r10
        mov     [r11+r9*8], rcx
        inc     r9
        mov     [r8+rdx*8], r9
        ret

; ---------------------------------------------------------------- cmpTerm
cmpTerm:
        push    rbx
        push    r12
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
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- cmpList
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
        jae     .gt
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

; ---------------------------------------------------------------- sameKey
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

; ---------------------------------------------------------------- sortAddr
; rcx = 数组, rdx = n（对地址排序）
sortAddr:
        push    rbx
        push    rsi
        push    rdi
        push    r13
        push    r14
        mov     rbx, rcx
        mov     r13, rdx
        mov     rsi, 1
.loop_i:
        cmp     rsi, r13
        jae     .done
        mov     r14, [rbx+rsi*8]        ; key
        mov     rdi, rsi
.loop_j:
        test    rdi, rdi
        jz      .place
        mov     rcx, [rbx+rdi*8-8]
        mov     rdx, r14
        call    cmpTerm
        cmp     eax, 0
        jle     .place
        mov     rax, [rbx+rdi*8-8]
        mov     [rbx+rdi*8], rax
        dec     rdi
        jmp     .loop_j
.place:
        mov     [rbx+rdi*8], r14
        inc     rsi
        jmp     .loop_i
.done:
        pop     r14
        pop     r13
        pop     rdi
        pop     rsi
        pop     rbx
        ret

; ---------------------------------------------------------------- dedupeAddr
; rcx = 数组, rdx = n -> rax = 新 n
dedupeAddr:
        push    rbx
        push    rbp
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rbx, rcx
        mov     r12, rdx
        xor     r13, r13
        xor     r14, r14
.next:
        cmp     r14, r12
        jae     .done
        mov     r15, [rbx+r14*8]
        lea     rbp, [r14+1]
.scan:
        cmp     rbp, r12
        jae     .flush
        mov     rcx, r15
        mov     rdx, [rbx+rbp*8]
        call    sameKey
        test    eax, eax
        jz      .flush
        mov     r9, [rbx+rbp*8]
        mov     rax, [r9+8]
        cmp     rax, [r15+8]
        jbe     .skip
        mov     r15, r9
.skip:
        inc     rbp
        jmp     .scan
.flush:
        mov     [rbx+r13*8], r15
        inc     r13
        mov     r14, rbp
        jmp     .next
.done:
        mov     rax, r13
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbp
        pop     rbx
        ret

; ---------------------------------------------------------------- subsumeAddr
; rcx = 数组, rdx = n -> rax = 新 n
subsumeAddr:
        mov     rax, rdx
        cmp     rdx, 2
        jb      .ret
        mov     r8, [rcx]
        cmp     qword [r8], 0
        jne     .ret
        mov     r9, [r8+8]
        mov     r10, 1
.scan:
        cmp     r10, rdx
        jae     .ret
        mov     r11, [rcx+r10*8]
        mov     r11, [r11+8]
        cmp     r11, r9
        jae     .drop
        inc     r10
        jmp     .scan
.drop:
        mov     r10, 1
.shift:
        cmp     r10, rdx
        jae     .shift_done
        mov     r11, [rcx+r10*8]
        mov     [rcx+r10*8-8], r11
        inc     r10
        jmp     .shift
.shift_done:
        mov     rax, rdx
        dec     rax
.ret:
        ret

; ---------------------------------------------------------------- copyTerms
; rcx = 地址数组, rdx = n, r8 = 额外 offset, r9 = 目标
copyTerms:
        push    rbx
        mov     rbx, r9
.loop:
        test    rdx, rdx
        jz      .done
        mov     rax, [rcx]
        mov     rax, [rax]
        mov     [rbx], rax
        mov     rax, [rcx]
        mov     rax, [rax+8]
        add     rax, r8
        mov     [rbx+8], rax
        mov     rax, [rcx]
        mov     rax, [rax+16]
        mov     [rbx+16], rax
        mov     rax, [rcx]
        mov     rax, [rax+24]
        mov     [rbx+24], rax
        mov     rax, [rcx]
        mov     rax, [rax+32]
        mov     [rbx+32], rax
        mov     rax, [rcx]
        mov     rax, [rax+40]
        mov     [rbx+40], rax
        add     rcx, 8
        add     rbx, TERM
        dec     rdx
        jmp     .loop
.done:
        mov     rax, rbx
        pop     rbx
        ret

; ---------------------------------------------------------------- flatten
; rcx = level 节点, r8d = off
flatten:
        push    rbx
        push    r12
        mov     rbx, rcx
        mov     r12d, r8d
        cmp     dword [rbx], 3
        jne     .leaf
        mov     rcx, [rbx+8]
        add     rcx, [rel baseVal]
        mov     r8d, r12d
        call    flatten
        mov     rcx, [rbx+16]
        add     rcx, [rel baseVal]
        mov     r8d, r12d
        call    flatten
        jmp     .done
.leaf:
        mov     rcx, rbx
        mov     r8d, r12d
        call    canon
        ; rax = ptr, rdx = count
        test    rdx, rdx
        jz      .done
        mov     r13, rax
        mov     r14, rdx
.emit:
        mov     rcx, r13
        call    pushAddr
        add     r13, TERM
        dec     r14
        jnz     .emit
.done:
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- canon
; rcx = level, r8d = off -> rax = 列表指针, rdx = 项数
canon:
        push    rbx
        push    rdi
        push    rbp
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rbx, rcx
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
        cmp     dword [rbx], 6
        je      .mvar
        cmp     dword [rbx], 3
        je      .max
        cmp     dword [rbx], 5
        je      .imax
        jmp     .zero
.zero:
        mov     ecx, 1
        call    alloc
        mov     qword [rax], 0
        mov     [rax+8], r12
        mov     qword [rax+16], 0
        mov     qword [rax+24], 0
        mov     qword [rax+32], 0
        mov     qword [rax+40], 0
        mov     rdx, 1
        jmp     .done
.param:
        mov     ecx, 1
        call    alloc
        mov     qword [rax], 1
        mov     [rax+8], r12
        mov     edx, [rbx+8]
        inc     rdx
        mov     [rax+16], rdx
        mov     qword [rax+24], 0
        mov     qword [rax+32], 0
        mov     qword [rax+40], 0
        mov     rdx, 1
        jmp     .done
.mvar:
        mov     ecx, 1
        call    alloc
        mov     qword [rax], 2
        mov     [rax+8], r12
        mov     edx, [rbx+8]
        inc     rdx
        mov     [rax+16], rdx
        mov     qword [rax+24], 0
        mov     qword [rax+32], 0
        mov     qword [rax+40], 0
        mov     rdx, 1
        jmp     .done
.max:
        mov     rax, [rel depth]
        inc     rax
        mov     [rel depth], rax
        lea     rcx, [rel counts]
        mov     qword [rcx+rax*8], 0
        mov     rcx, [rbx+8]
        add     rcx, [rel baseVal]
        mov     r8d, r12d
        call    flatten
        mov     rcx, [rbx+16]
        add     rcx, [rel baseVal]
        mov     r8d, r12d
        call    flatten
        call    getArr
        mov     r13, rax
        mov     rax, [rel depth]
        lea     rcx, [rel counts]
        mov     r14, [rcx+rax*8]
        mov     rcx, r13
        mov     rdx, r14
        call    sortAddr
        mov     rcx, r13
        mov     rdx, r14
        call    dedupeAddr
        mov     r14, rax
        mov     rcx, r13
        mov     rdx, r14
        call    subsumeAddr
        mov     r14, rax
        mov     rax, [rel depth]
        dec     rax
        mov     [rel depth], rax
        mov     rcx, r14
        call    alloc
        mov     r15, rax
        mov     rcx, r13
        mov     rdx, r14
        xor     r8d, r8d
        mov     r9, r15
        call    copyTerms
        mov     rax, r15
        mov     rdx, r14
        jmp     .done
.imax:
        mov     rcx, [rbx+8]
        add     rcx, [rel baseVal]
        xor     r8d, r8d
        call    canon
        mov     r13, rax
        mov     r14, rdx
        mov     rcx, [rbx+16]
        add     rcx, [rel baseVal]
        xor     r8d, r8d
        call    canon
        mov     r15, rax
        mov     rbp, rdx
        ; rhs 里只要有一项 off > 0（succ），就是 is_not_zero -> 退化成 max
        xor     r9, r9
.scan_off:
        cmp     r9, rbp
        jae     .check_zero
        imul    rax, r9, TERM
        mov     rax, [r15+rax+8]
        test    rax, rax
        jnz     .rhs_nz
        inc     r9
        jmp     .scan_off
.check_zero:
        cmp     rbp, 1
        jne     .atom
        cmp     qword [r15], 0
        jne     .atom
        cmp     qword [r15+8], 0
        jne     .rhs_nz
        mov     ecx, 1
        call    alloc
        mov     qword [rax], 0
        mov     [rax+8], r12
        mov     qword [rax+16], 0
        mov     qword [rax+24], 0
        mov     qword [rax+32], 0
        mov     qword [rax+40], 0
        mov     rdx, 1
        jmp     .done
.rhs_nz:
        lea     rdi, [rel imaxArr]
        xor     r9, r9
        mov     rcx, r13
        mov     r10, r14
.l1loop:
        test    r10, r10
        jz      .l2prep
        mov     [rdi+r9*8], rcx
        add     rcx, TERM
        inc     r9
        dec     r10
        jmp     .l1loop
.l2prep:
        mov     rcx, r15
        mov     r10, rbp
.l2loop:
        test    r10, r10
        jz      .mkmax
        mov     [rdi+r9*8], rcx
        add     rcx, TERM
        inc     r9
        dec     r10
        jmp     .l2loop
.mkmax:
        mov     r14, r9
        mov     rcx, rdi
        mov     rdx, r14
        call    sortAddr
        mov     rcx, rdi
        mov     rdx, r14
        call    dedupeAddr
        mov     r14, rax
        mov     rcx, rdi
        mov     rdx, r14
        call    subsumeAddr
        mov     r14, rax
        mov     rcx, r14
        call    alloc
        mov     r13, rax
        mov     rcx, rdi
        mov     rdx, r14
        mov     r8d, r12d
        mov     r9, r13
        call    copyTerms
        mov     rax, r13
        mov     rdx, r14
        jmp     .done
.atom:
        ; imax u u = u
        mov     rcx, r13
        mov     rdx, r14
        mov     r8, r15
        mov     r9, rbp
        call    cmpList
        test    eax, eax
        jz      .shift_rhs
        cmp     r14, 1
        jne     .emit
        cmp     qword [r13], 0
        jne     .emit
        cmp     qword [r13+8], 1
        ja      .emit
.shift_rhs:
        lea     rdi, [rel imaxArr]
        xor     r9, r9
        mov     rcx, r15
        mov     r10, rbp
.fill:
        test    r10, r10
        jz      .fill_done
        mov     [rdi+r9*8], rcx
        add     rcx, TERM
        inc     r9
        dec     r10
        jmp     .fill
.fill_done:
        mov     rcx, rbp
        call    alloc
        mov     r13, rax
        mov     rcx, rdi
        mov     rdx, rbp
        mov     r8d, r12d
        mov     r9, r13
        call    copyTerms
        mov     rax, r13
        mov     rdx, rbp
        jmp     .done
.emit:
        mov     ecx, 1
        call    alloc
        mov     qword [rax], 3
        mov     [rax+8], r12
        mov     [rax+16], r13
        mov     [rax+24], r14
        mov     [rax+32], r15
        mov     [rax+40], rbp
        mov     rdx, 1
.done:
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbp
        pop     rdi
        pop     rbx
        ret

; ---------------------------------------------------------------- lvl_equiv
; rcx = a, rdx = b -> eax = 1/0
lvl_equiv:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        push    rbp
        mov     qword [rel arenaTop], 0
        mov     qword [rel depth], 0
        mov     rbx, rdx
        xor     r8d, r8d
        call    canon
        mov     r13, rax
        mov     r14, rdx
        mov     rcx, rbx
        xor     r8d, r8d
        call    canon
        mov     r15, rax
        mov     rbp, rdx
        mov     rcx, r13
        mov     rdx, r14
        mov     r8, r15
        mov     r9, rbp
        call    cmpList
        test    eax, eax
        jnz     .no
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     rbp
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

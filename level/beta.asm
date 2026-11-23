; beta.asm -- 受限 beta：app(lam t body) arg，body 只含 bvar 0、arg 闭合
        bits 64
        section .bss
        align 16
betaOut: resb 65536
betaRootVal: resq 1
replacePtr: resq 1
replaceWith: resq 1
tblPtr: resq 1
argBase: resq 1
spineArgs: resq 64
spineN:  resq 8
iotaArgs: resq 64
recNparams: resq 1
recMajorIdx: resq 1
recRules: resq 1
ruleNfields: resq 1
ruleRhs: resq 1
fieldCnt: resq 1
argN:    resq 1
betaLen:  resq 1
ibase:   resq 1
subst:   resq 1

        section .text
        global l_exprBetaBa
        global l_exprBetaBaT
        global l_exprSubstBaT
        global l_exprIotaBaT
        global l_exprProjBa
        global l_exprProjBaT
        global l_betaByte
        global l_hasGE1
        global l_hasBvar
        global l_copyAt
        global l_outPtr
        global l_betaRoot

; ---------------------------------------------------------------- emit
; rax=tag rdx=a rcx=b r8=c ; 返回 rax=节点偏移
emit4:
        push    r9
        mov     r9, [rel betaLen]
        lea     r10, [rel betaOut]
        add     r10, r9
        mov     [r10], rax
        mov     [r10+8], rdx
        mov     [r10+16], rcx
        mov     [r10+24], r8
        add     r9, 32
        mov     [rel betaLen], r9
        sub     r9, 32
        mov     rax, r9
        pop     r9
        ret

; ---------------------------------------------------------------- hasBvarGE1
; rcx = node -> eax
hasGE1:
        push    rbx
        mov     rbx, rcx
        mov     rax, [rbx]
        cmp     rax, 1
        jne     .recurse
        mov     rax, [rbx+8]
        cmp     rax, 1
        jae     .yes
        jmp     .no
.recurse:
        ; 遍历孩子
        cmp     rax, 5
        je      .two
        cmp     rax, 6
        je      .two
        cmp     rax, 7
        je      .two
        cmp     rax, 8
        je      .three
        cmp     rax, 10
        je      .one
        cmp     rax, 11
        je      .oneC
        cmp     rax, 4
        je      .oneL
        cmp     rax, 21
        je      .one
        cmp     rax, 22
        je      .two
        cmp     rax, 23
        je      .two
        cmp     rax, 30
        je      .two
        jmp     .no
.oneC:
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    hasGE1
        jmp     .out
.oneL:
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasGE1
        jmp     .out
.one:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasGE1
        jmp     .out
.two:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasGE1
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasGE1
        jmp     .out
.three:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasGE1
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasGE1
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    hasGE1
        jmp     .out
.yes:
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     rbx
        ret

; ---------------------------------------------------------------- hasBvar
; rcx = node -> eax（任意 bvar）
hasBvar:
        push    rbx
        mov     rbx, rcx
        mov     rax, [rbx]
        cmp     rax, 1
        jne     .recurse
        mov     eax, 1
        jmp     .out
.recurse:
        cmp     rax, 5
        je      .two
        cmp     rax, 6
        je      .two
        cmp     rax, 7
        je      .two
        cmp     rax, 8
        je      .three
        cmp     rax, 10
        je      .one
        cmp     rax, 11
        je      .oneC
        cmp     rax, 4
        je      .oneL
        cmp     rax, 21
        je      .one
        cmp     rax, 22
        je      .two
        cmp     rax, 23
        je      .two
        cmp     rax, 30
        je      .two
        jmp     .no
.oneC:
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    hasBvar
        jmp     .out
.oneL:
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasBvar
        jmp     .out
.one:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasBvar
        jmp     .out
.two:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasBvar
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasBvar
        jmp     .out
.three:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    hasBvar
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    hasBvar
        test    eax, eax
        jnz     .yes
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    hasBvar
        jmp     .out
.yes:
        mov     eax, 1
        jmp     .out
.no:
        xor     eax, eax
.out:
        pop     rbx
        ret

; ---------------------------------------------------------------- copyNode
; rcx = 输入节点指针 -> rax = 新 offset, rdx = 新 out 尾
copyNode:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        sub     rsp, 8
        mov     rbx, rcx
        cmp     rbx, [rel replacePtr]
        jne     .norepl
        mov     rcx, [rel replaceWith]
        mov     qword [rel replacePtr], 0
        call    copyNode
        jmp     .fin
.norepl:
        mov     rax, [rbx]
        cmp     rax, 1
        je      .bvar
        cmp     rax, 5
        je      .two
        cmp     rax, 6
        je      .binder
        cmp     rax, 7
        je      .binder
        cmp     rax, 8
        je      .three
        cmp     rax, 10
        je      .oneA
        cmp     rax, 11
        je      .proj
        cmp     rax, 4
        je      .const
        cmp     rax, 21
        je      .oneA
        cmp     rax, 22
        je      .two
        cmp     rax, 23
        je      .two
        cmp     rax, 30
        je      .two
        ; 叶子：2,3,9,20,24,25,31 等
        mov     rax, [rbx]
        mov     rdx, [rbx+8]
        mov     rcx, [rbx+16]
        mov     r8, [rbx+24]
        call    emit4
        jmp     .fin
.bvar:
        mov     rax, [rbx+8]
        mov     r9, [rel subst]
        test    r9, r9
        jz      .bvar_args
        test    rax, rax
        jnz     .bvar_dec
        mov     rcx, r9
        mov     rax, [rel subst]
        mov     qword [rel subst], 0
        push    rax
        call    copyNode
        mov     rdx, rax
        pop     rax
        mov     [rel subst], rax
        mov     rax, rdx
        jmp     .fin
.bvar_args:
        mov     r10, [rel argN]
        test    r10, r10
        jz      .bvar_emit
        cmp     rax, r10
        jae     .bvar_shift
        mov     rcx, [rel argBase]
        mov     rcx, [rcx+rax*8]
        add     rcx, [rel ibase]
        push    r10
        mov     qword [rel argN], 0
        call    copyNode
        pop     r10
        mov     [rel argN], r10
        jmp     .fin
.bvar_shift:
        sub     rax, r10
        mov     rdx, rax
        mov     rax, 1
        xor     ecx, ecx
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.bvar_dec:
        dec     rax
        mov     rdx, rax
        mov     rax, 1
        xor     ecx, ecx
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.bvar_emit:
        mov     rax, 1
        mov     rdx, [rbx+8]
        xor     ecx, ecx
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.oneA:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax                ; 子偏移
        mov     rax, [rbx]
        mov     rdx, r12
        xor     ecx, ecx
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.proj:
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax
        mov     rax, [rbx]
        mov     rdx, [rbx+8]
        mov     rcx, [rbx+16]
        mov     r8, r12
        call    emit4
        jmp     .fin
.const:
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax
        mov     rax, 4
        mov     rdx, [rbx+8]
        mov     rcx, r12
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.two:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r13, rax
        mov     rax, [rbx]
        mov     rdx, r12
        mov     rcx, r13
        xor     r8d, r8d
        call    emit4
        jmp     .fin
.binder:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r13, rax
        mov     rax, [rbx]
        mov     rdx, r12
        mov     rcx, r13
        mov     r8, [rbx+24]
        call    emit4
        jmp     .fin
.three:
        mov     rcx, [rbx+8]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r12, rax
        mov     rcx, [rbx+16]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r13, rax
        mov     rcx, [rbx+24]
        add     rcx, [rel ibase]
        call    copyNode
        mov     r14, rax
        mov     rax, [rbx]
        mov     rdx, r12
        mov     rcx, r13
        mov     r8, r14
        call    emit4
        jmp     .fin
.fin:
        mov     rdx, [rel betaLen]
        add     rsp, 8
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- l_exprSubstBaT
; rcx = ba, rdx = off, r8 = argsOff, r9 = nargs
l_exprSubstBaT:
        push    rbx
        push    r12
        push    r13
        push    r14
        lea     rax, [rcx+24]
        mov     [rel ibase], rax
        mov     r14, rax
        mov     qword [rel betaLen], 0
        mov     qword [rel subst], 0
        mov     qword [rel replacePtr], 0
        mov     qword [rel replaceWith], 0
        mov     qword [rel tblPtr], 0
        mov     rbx, r8
        shr     rbx, 1
        add     rbx, r14
        mov     [rel argBase], rbx
        mov     rbx, r9
        shr     rbx, 1
        mov     [rel argN], rbx
        mov     rcx, rdx
        shr     rcx, 1
        add     rcx, r14
        call    copyNode
        mov     [rel betaRootVal], rax
        mov     rax, [rel betaLen]
        lea     rax, [rax*2+1]
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- findBody
; rcx = name id -> rax = body offset（-1 表示没有）
findBody:
        push    rbx
        mov     rbx, [rel tblPtr]
.loop:
        test    rbx, rbx
        jz      .miss
        cmp     qword [rbx], 40
        jne     .miss
        cmp     qword [rbx+8], rcx
        je      .hit
        mov     rbx, [rbx+24]
        add     rbx, [rel ibase]
        jmp     .loop
.hit:
        mov     rax, [rbx+16]
        jmp     .out
.miss:
        mov     rax, -1
.out:
        pop     rbx
        ret

; ---------------------------------------------------------------- spine
; rcx = node -> rax = head const name（-1 不是 const），args 逆序（最外层在前）存 spineArgs
spine:
        push    rbx
        mov     rbx, rcx
        xor     r8, r8
.s_loop:
        cmp     qword [rbx], 5
        jne     .s_head
        mov     rax, [rbx+16]
        lea     r10, [rel spineArgs]
        mov     [r10 + r8*8], rax
        inc     r8
        mov     rbx, [rbx+8]
        add     rbx, [rel ibase]
        jmp     .s_loop
.s_head:
        mov     [rel spineN], r8
        cmp     qword [rbx], 4
        jne     .s_no
        mov     rax, [rbx+8]
        jmp     .s_out
.s_no:
        mov     rax, -1
.s_out:
        pop     rbx
        ret

; ---------------------------------------------------------------- findCtor
; rcx = name -> rax = nparams（-1 表示没有）
findCtor:
        push    rbx
        mov     rbx, [rel tblPtr]
.loop:
        test    rbx, rbx
        jz      .miss
        cmp     qword [rbx], 52
        jne     .miss
        cmp     qword [rbx+8], rcx
        je      .hit
        mov     rbx, [rbx+24]
        add     rbx, [rel ibase]
        jmp     .loop
.hit:
        mov     rax, [rbx+16]
        jmp     .out
.miss:
        mov     rax, -1
.out:
        pop     rbx
        ret

; ---------------------------------------------------------------- l_exprIotaBaT
; rcx = ba, rdx = off, r8 = table off
; 表: 50=(name, nparams, majorIdx, rulesOff, next)  51=(ctor, nfields, rhsOff, next)
; rhs 模板的 bvar 顺序: 先字段，再 root spine 的实参（逆序：major, minor, ..., params）
l_exprIotaBaT:
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        sub     rsp, 8
        lea     rax, [rcx+24]
        mov     [rel ibase], rax
        mov     r14, rax
        mov     qword [rel betaLen], 0
        mov     qword [rel subst], 0
        mov     qword [rel replacePtr], 0
        mov     qword [rel replaceWith], 0
        mov     qword [rel argN], 0
        mov     rax, r8
        shr     rax, 1
        add     rax, r14
        mov     [rel tblPtr], rax
        mov     r13, rdx
        shr     r13, 1
        add     r13, r14
        mov     rcx, r13
        mov     qword [rel spineN], 0
        call    spine
        cmp     rax, -1
        je      .nocopy
        mov     r12, rax
        mov     rbx, [rel tblPtr]
.rec_loop:
        test    rbx, rbx
        jz      .nocopy
        cmp     qword [rbx], 50
        jne     .nocopy
        cmp     qword [rbx+8], r12
        je      .rec_hit
        mov     rbx, [rbx+40]
        add     rbx, r14
        jmp     .rec_loop
.rec_hit:
        mov     rax, [rbx+24]
        mov     [rel recMajorIdx], rax
        mov     rax, [rbx+32]
        add     rax, r14
        mov     [rel recRules], rax
        ; major 的 spine
        lea     r10, [rel spineArgs]
        mov     rax, [rel recMajorIdx]
        mov     rcx, [r10 + rax*8]
        add     rcx, r14
        call    spine
        cmp     rax, -1
        je      .nocopy
        mov     r12, rax
        mov     r15, [rel spineN]
        mov     [rel fieldCnt], r15
        lea     r10, [rel spineArgs]
        lea     r11, [rel iotaArgs]
        xor     r8, r8
.mv:
        cmp     r8, r15
        jae     .mv_done
        mov     rax, r15
        sub     rax, r8
        dec     rax
        mov     rcx, [r10 + rax*8]
        mov     [r11 + r8*8], rcx
        inc     r8
        jmp     .mv
.mv_done:
        mov     rbx, [rel recRules]
.rule_loop:
        test    rbx, rbx
        jz      .nocopy
        cmp     qword [rbx], 51
        jne     .nocopy
        cmp     qword [rbx+8], r12
        je      .rule_hit
        mov     rbx, [rbx+32]
        add     rbx, r14
        jmp     .rule_loop
.rule_hit:
        mov     rax, [rbx+24]
        mov     [rel ruleRhs], rax
        mov     rcx, r13
        mov     qword [rel spineN], 0
        call    spine
        mov     r15, [rel spineN]
        lea     r10, [rel spineArgs]
        lea     r11, [rel iotaArgs]
        mov     r9, [rel fieldCnt]
        xor     r8, r8
.cp:
        cmp     r8, r15
        jae     .cp_done
        mov     rax, [r10 + r8*8]
        mov     rcx, r9
        add     rcx, r8
        mov     [r11 + rcx*8], rax
        inc     r8
        jmp     .cp
.cp_done:
        mov     rax, r9
        add     rax, r15
        mov     [rel argN], rax
        lea     rax, [rel iotaArgs]
        mov     [rel argBase], rax
        mov     rcx, [rel ruleRhs]
        add     rcx, r14
        call    copyNode
        jmp     .done
.nocopy:
        mov     rcx, r13
        call    copyNode
.done:
        mov     [rel betaRootVal], rax
        mov     rax, [rel betaLen]
        lea     rax, [rax*2+1]
        add     rsp, 8
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- l_exprProjBaT
; rcx = ba, rdx = off（无表）
l_exprProjBa:
        xor     r8d, r8d
        jmp     l_exprProjBaT

; rcx = ba, rdx = off, r8 = table off
l_exprProjBaT:
        push    rbx
        push    r12
        push    r13
        push    r14
        lea     rax, [rcx+24]
        mov     [rel ibase], rax
        mov     r14, rax
        mov     qword [rel betaLen], 0
        mov     qword [rel subst], 0
        mov     qword [rel replacePtr], 0
        mov     qword [rel replaceWith], 0
        mov     qword [rel argN], 0
        mov     rax, r8
        shr     rax, 1
        add     rax, r14
        mov     [rel tblPtr], rax
        mov     r13, rdx
        shr     r13, 1
        add     r13, r14
        cmp     qword [r13], 11
        jne     .nocopy
        mov     r12, [r13+24]
        add     r12, r14
        mov     rcx, r12
        call    spine
        cmp     rax, -1
        je      .nocopy
        mov     [rel ruleNfields], rax
        mov     rcx, rax
        call    findCtor
        cmp     rax, -1
        jne     .have_np
        xor     eax, eax
.have_np:
        mov     rbx, [rel spineN]
        mov     rdx, [r13+16]
        add     rdx, rax
        cmp     rdx, rbx
        jae     .nocopy
        mov     rcx, rbx
        sub     rcx, rdx
        dec     rcx
        lea     r10, [rel spineArgs]
        mov     rcx, [r10 + rcx*8]
        add     rcx, r14
        call    copyNode
        jmp     .done
.nocopy:
        mov     rcx, r13
        call    copyNode
.done:
        mov     [rel betaRootVal], rax
        mov     rax, [rel betaLen]
        lea     rax, [rax*2+1]
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- l_exprBetaBa
; rcx = ba, rdx = off -> lean_object*（len）
l_exprBetaBa:
        xor     r8d, r8d
        jmp     l_exprBetaBaT

; rcx = ba, rdx = off, r8 = table off
l_exprBetaBaT:
        push    rbx
        push    r12
        push    r13
        push    r14
        lea     rax, [rcx+24]
        mov     [rel ibase], rax
        mov     r14, rax
        mov     qword [rel betaLen], 0
        mov     qword [rel subst], 0
        mov     qword [rel replacePtr], 0
        mov     qword [rel replaceWith], 0
        mov     qword [rel argN], 0
        mov     rax, r8
        shr     rax, 1
        add     rax, r14
        mov     [rel tblPtr], rax
        mov     rbx, rdx
        shr     rbx, 1
        add     rbx, r14                ; 根节点指针
        cmp     qword [rbx], 5
        jne     .maybe_let
        mov     r12, [rbx+8]
        add     r12, r14
        cmp     qword [r12], 6
        je      .app_lam
        cmp     qword [r12], 4
        jne     .nocopy
        mov     rcx, [r12+8]
        call    findBody
        cmp     rax, -1
        je      .nocopy
        lea     rdx, [r14+rax]
        mov     [rel replacePtr], r12
        mov     [rel replaceWith], rdx
        mov     rcx, rbx
        call    copyNode
        jmp     .done
.app_lam:
        mov     r13, [r12+16]
        add     r13, r14                ; body
        mov     rcx, [rbx+16]
        add     rcx, r14
        mov     [rel subst], rcx
        mov     rcx, r13
        call    copyNode
        jmp     .done
.maybe_let:
        cmp     qword [rbx], 8
        jne     .maybe_const
        mov     rcx, [rbx+16]
        add     rcx, r14
        mov     [rel subst], rcx
        mov     rcx, [rbx+24]
        add     rcx, r14
        call    copyNode
        jmp     .done
.maybe_const:
        cmp     qword [rbx], 4
        jne     .nocopy
        mov     rcx, [rbx+8]
        call    findBody
        cmp     rax, -1
        je      .nocopy
        lea     rcx, [r14+rax]
        call    copyNode
        jmp     .done
.nocopy:
        mov     rcx, rbx
        call    copyNode
.done:
        mov     [rel betaRootVal], rax
        mov     rax, [rel betaLen]
        lea     rax, [rax*2+1]
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        ret

; ---------------------------------------------------------------- l_betaByte
; lean_object* l_betaByte(lean_object* i) -> lean_object*（byte）
l_betaByte:
        shr     rcx, 1
        lea     rax, [rel betaOut]
        movzx   eax, byte [rax+rcx]
        lea     rax, [rax*2+1]
        ret

; ---------------------------------------------------------------- 调试导出
; uint64 l_hasGE1(ptr)
l_hasGE1:
        jmp     hasGE1

; uint64 l_hasBvar(ptr)
l_hasBvar:
        jmp     hasBvar

; uint64 l_copyAt(ptr) -> 输出长度（根偏移在 betaRootVal）
l_copyAt:
        push    rbx
        mov     rbx, rcx
        mov     qword [rel betaLen], 0
        mov     rcx, rbx
        call    copyNode
        mov     rax, [rel betaLen]
        pop     rbx
        ret

l_outPtr:
        lea     rax, [rel betaOut]
        ret

l_betaRoot:
        mov     rax, [rel betaRootVal]
        lea     rax, [rax*2+1]
        ret
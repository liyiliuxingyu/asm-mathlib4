	.def	@feat.00;
	.scl	3;
	.type	0;
	.endef
	.globl	@feat.00
@feat.00 = 0
	.att_syntax
	.file	"lib.c"
	.def	l_fib;
	.scl	2;
	.type	32;
	.endef
	.text
	.globl	l_fib                           # -- Begin function l_fib
	.p2align	4
l_fib:                                  # @l_fib
# %bb.0:
	pushq	%rsi
	pushq	%rdi
	pushq	%rbx
	subq	$32, %rsp
	testb	$1, %cl
	je	.LBB0_23
# %bb.1:
	cmpq	$1, %rcx
	je	.LBB0_20
# %bb.2:
	movl	$3, %eax
	jbe	.LBB0_22
# %bb.3:
	addq	$-2, %rcx
	testb	$1, %cl
	je	.LBB0_25
.LBB0_4:
	cmpq	$1, %rcx
	je	.LBB0_21
# %bb.5:
	movl	$1, %edi
	jbe	.LBB0_7
# %bb.6:
	addq	$-2, %rcx
	movq	%rcx, %rdi
.LBB0_7:
	testb	$1, %dil
	je	.LBB0_30
# %bb.8:
	movq	%rdi, %rax
	shrq	%rax
	incq	%rax
	js	.LBB0_32
# %bb.9:
	leaq	1(,%rax,2), %rbx
.LBB0_10:
	movq	%rbx, %rcx
	callq	l_fib
	movq	%rax, %rsi
	testb	$1, %bl
	jne	.LBB0_13
# %bb.11:
	movl	(%rbx), %eax
	cmpl	$2, %eax
	jl	.LBB0_41
# %bb.12:
	decl	%eax
	movl	%eax, (%rbx)
.LBB0_13:
	movq	%rdi, %rcx
	callq	l_fib
	testb	$1, %dil
	jne	.LBB0_16
# %bb.14:
	movl	(%rdi), %ecx
	cmpl	$2, %ecx
	jl	.LBB0_43
# %bb.15:
	decl	%ecx
	movl	%ecx, (%rdi)
.LBB0_16:
	testb	$1, %sil
	je	.LBB0_31
# %bb.17:
	testb	$1, %al
	je	.LBB0_34
# %bb.18:
	shrq	%rsi
	shrq	%rax
	addq	%rsi, %rax
	js	.LBB0_40
# %bb.19:
	leaq	1(,%rax,2), %rax
	jmp	.LBB0_22
.LBB0_20:
	movl	$1, %eax
	jmp	.LBB0_22
.LBB0_23:
	movl	$1, %edx
	movq	%rcx, %rsi
	callq	lean_nat_big_eq
	movl	%eax, %edx
	movl	$1, %eax
	testb	%dl, %dl
	jne	.LBB0_22
# %bb.24:
	movl	$3, %edx
	movq	%rsi, %rcx
	callq	lean_nat_big_sub
	movq	%rax, %rcx
	testb	$1, %cl
	jne	.LBB0_4
.LBB0_25:
	movl	$1, %edx
	movq	%rcx, %rsi
	callq	lean_nat_big_eq
	testb	%al, %al
	je	.LBB0_28
# %bb.26:
	movl	(%rsi), %eax
	cmpl	$2, %eax
	jl	.LBB0_45
# %bb.27:
	decl	%eax
	movl	%eax, (%rsi)
.LBB0_21:
	movl	$3, %eax
.LBB0_22:
	addq	$32, %rsp
	popq	%rbx
	popq	%rdi
	popq	%rsi
	retq
.LBB0_28:
	movl	$3, %edx
	movq	%rsi, %rcx
	callq	lean_nat_big_sub
	movq	%rax, %rdi
	movl	(%rsi), %eax
	cmpl	$2, %eax
	jl	.LBB0_47
# %bb.29:
	decl	%eax
	movl	%eax, (%rsi)
	jmp	.LBB0_7
.LBB0_30:
	movl	$3, %edx
	movq	%rdi, %rcx
	callq	lean_nat_big_add
	jmp	.LBB0_33
.LBB0_31:
	movq	%rsi, %rcx
	movq	%rax, %rdx
	movq	%rax, %rdi
	callq	lean_nat_big_add
	movq	%rdi, %rcx
	testb	$1, %cl
	je	.LBB0_35
	jmp	.LBB0_38
.LBB0_32:
	movabsq	$-9223372036854775808, %rcx     # imm = 0x8000000000000000
	callq	lean_big_usize_to_nat
.LBB0_33:
	movq	%rax, %rbx
	jmp	.LBB0_10
.LBB0_34:
	movq	%rsi, %rcx
	movq	%rax, %rdx
	movq	%rax, %rdi
	callq	lean_nat_big_add
	movq	%rdi, %rcx
.LBB0_35:
	movl	(%rcx), %edx
	cmpl	$2, %edx
	jl	.LBB0_49
# %bb.36:
	decl	%edx
	movl	%edx, (%rcx)
.LBB0_37:
	testb	$1, %sil
	jne	.LBB0_22
.LBB0_38:
	movl	(%rsi), %ecx
	cmpl	$2, %ecx
	jl	.LBB0_51
# %bb.39:
	decl	%ecx
	movl	%ecx, (%rsi)
	jmp	.LBB0_22
.LBB0_40:
	movq	%rax, %rcx
	addq	$32, %rsp
	popq	%rbx
	popq	%rdi
	popq	%rsi
	jmp	lean_big_usize_to_nat           # TAILCALL
.LBB0_41:
	testl	%eax, %eax
	je	.LBB0_13
# %bb.42:
	movq	%rbx, %rcx
	callq	lean_dec_ref_cold
	jmp	.LBB0_13
.LBB0_43:
	testl	%ecx, %ecx
	je	.LBB0_16
# %bb.44:
	movq	%rdi, %rcx
	movq	%rax, %rdi
	callq	lean_dec_ref_cold
	movq	%rdi, %rax
	jmp	.LBB0_16
.LBB0_45:
	testl	%eax, %eax
	je	.LBB0_21
# %bb.46:
	movq	%rsi, %rcx
	callq	lean_dec_ref_cold
	jmp	.LBB0_21
.LBB0_47:
	testl	%eax, %eax
	je	.LBB0_7
# %bb.48:
	movq	%rsi, %rcx
	callq	lean_dec_ref_cold
	jmp	.LBB0_7
.LBB0_49:
	testl	%edx, %edx
	je	.LBB0_37
# %bb.50:
	movq	%rax, %rdi
	callq	lean_dec_ref_cold
	movq	%rdi, %rax
	jmp	.LBB0_37
.LBB0_51:
	movq	%rax, %rdi
	testl	%ecx, %ecx
	je	.LBB0_53
# %bb.52:
	movq	%rsi, %rcx
	callq	lean_dec_ref_cold
.LBB0_53:
	movq	%rdi, %rax
	jmp	.LBB0_22
                                        # -- End function
	.def	l_fib___boxed;
	.scl	2;
	.type	32;
	.endef
	.globl	l_fib___boxed                   # -- Begin function l_fib___boxed
	.p2align	4
l_fib___boxed:                          # @l_fib___boxed
# %bb.0:
	pushq	%rsi
	subq	$32, %rsp
	movq	%rcx, %rsi
	callq	l_fib
	testb	$1, %sil
	jne	.LBB1_5
# %bb.1:
	movl	(%rsi), %ecx
	cmpl	$2, %ecx
	jl	.LBB1_3
# %bb.2:
	decl	%ecx
	movl	%ecx, (%rsi)
.LBB1_5:
	addq	$32, %rsp
	popq	%rsi
	retq
.LBB1_3:
	testl	%ecx, %ecx
	je	.LBB1_5
# %bb.4:
	movq	%rsi, %rcx
	movq	%rax, %rsi
	callq	lean_dec_ref_cold
	movq	%rsi, %rax
	jmp	.LBB1_5
                                        # -- End function
	.def	l_add3;
	.scl	2;
	.type	32;
	.endef
	.globl	l_add3                          # -- Begin function l_add3
	.p2align	4
l_add3:                                 # @l_add3
# %bb.0:
	leaq	(%rcx,%rcx,2), %rax
	incq	%rax
	retq
                                        # -- End function
	.def	l_add3___boxed;
	.scl	2;
	.type	32;
	.endef
	.globl	l_add3___boxed                  # -- Begin function l_add3___boxed
	.p2align	4
l_add3___boxed:                         # @l_add3___boxed
# %bb.0:
	pushq	%rsi
	subq	$32, %rsp
	movl	4(%rcx), %eax
	cmpl	$-201326592, %eax               # imm = 0xF4000000
	jae	.LBB3_1
# %bb.2:
	testl	$16711680, %eax                 # imm = 0xFF0000
	jne	.LBB3_3
.LBB3_4:
	cmpl	$-201326592, %eax               # imm = 0xF4000000
	jae	.LBB3_5
.LBB3_7:
	movq	8(%rcx), %rsi
	movl	(%rcx), %eax
	cmpl	$2, %eax
	jl	.LBB3_9
# %bb.8:
	decl	%eax
	movl	%eax, (%rcx)
.LBB3_11:
	leaq	(%rsi,%rsi,2), %rsi
	incq	%rsi
	movl	$16, %ecx
	callq	lean_alloc_small_object_core
	movl	$1, (%rax)
	movzwl	4(%rax), %ecx
	movl	%ecx, 4(%rax)
	movq	%rsi, 8(%rax)
	addq	$32, %rsp
	popq	%rsi
	retq
.LBB3_1:
	leaq	.L.str(%rip), %rax
	leaq	.L.str.2(%rip), %r8
	movq	%rcx, %rsi
	movq	%rax, %rcx
	movl	$839, %edx                      # imm = 0x347
	callq	lean_notify_assert
	movq	%rsi, %rcx
	movl	4(%rsi), %eax
	testl	$16711680, %eax                 # imm = 0xFF0000
	je	.LBB3_4
.LBB3_3:
	leaq	.L.str(%rip), %rax
	leaq	.L.str.1(%rip), %r8
	movq	%rcx, %rsi
	movq	%rax, %rcx
	movl	$919, %edx                      # imm = 0x397
	callq	lean_notify_assert
	movq	%rsi, %rcx
	movl	4(%rsi), %eax
	cmpl	$-201326592, %eax               # imm = 0xF4000000
	jb	.LBB3_7
.LBB3_5:
	leaq	.L.str(%rip), %rax
	leaq	.L.str.2(%rip), %r8
	movq	%rcx, %rsi
	movq	%rax, %rcx
	movl	$844, %edx                      # imm = 0x34C
	callq	lean_notify_assert
	movq	%rsi, %rcx
	cmpl	$-201326592, 4(%rsi)            # imm = 0xF4000000
	jb	.LBB3_7
# %bb.6:
	leaq	.L.str(%rip), %rcx
	leaq	.L.str.2(%rip), %r8
	movl	$765, %edx                      # imm = 0x2FD
	callq	lean_notify_assert
	movq	%rsi, %rcx
	jmp	.LBB3_7
.LBB3_9:
	testl	%eax, %eax
	je	.LBB3_11
# %bb.10:
	callq	lean_dec_ref_cold
	jmp	.LBB3_11
                                        # -- End function
	.def	l_doubleNat;
	.scl	2;
	.type	32;
	.endef
	.globl	l_doubleNat                     # -- Begin function l_doubleNat
	.p2align	4
l_doubleNat:                            # @l_doubleNat
# %bb.0:
	testb	$1, %cl
	je	.LBB4_3
# %bb.1:
	movq	%rcx, %rax
	andq	$-2, %rax
	testq	%rcx, %rcx
	js	.LBB4_2
# %bb.4:
	leaq	1(,%rax,2), %rax
	retq
.LBB4_3:
	movq	%rcx, %rdx
	jmp	lean_nat_big_add                # TAILCALL
.LBB4_2:
	movq	%rax, %rcx
	jmp	lean_big_usize_to_nat           # TAILCALL
                                        # -- End function
	.def	l_doubleNat___boxed;
	.scl	2;
	.type	32;
	.endef
	.globl	l_doubleNat___boxed             # -- Begin function l_doubleNat___boxed
	.p2align	4
l_doubleNat___boxed:                    # @l_doubleNat___boxed
# %bb.0:
	pushq	%rsi
	pushq	%rdi
	subq	$40, %rsp
	testb	$1, %cl
	je	.LBB5_4
# %bb.1:
	movq	%rcx, %rax
	andq	$-2, %rax
	testq	%rcx, %rcx
	js	.LBB5_3
# %bb.2:
	leaq	1(,%rax,2), %rax
.LBB5_9:
	addq	$40, %rsp
	popq	%rdi
	popq	%rsi
	retq
.LBB5_4:
	movq	%rcx, %rsi
	movq	%rcx, %rdx
	callq	lean_nat_big_add
	movl	(%rsi), %edx
	cmpl	$2, %edx
	jl	.LBB5_6
# %bb.5:
	decl	%edx
	movl	%edx, (%rsi)
	jmp	.LBB5_9
.LBB5_3:
	movq	%rax, %rcx
	addq	$40, %rsp
	popq	%rdi
	popq	%rsi
	jmp	lean_big_usize_to_nat           # TAILCALL
.LBB5_6:
	movq	%rax, %rdi
	testl	%edx, %edx
	je	.LBB5_8
# %bb.7:
	movq	%rsi, %rcx
	callq	lean_dec_ref_cold
.LBB5_8:
	movq	%rdi, %rax
	jmp	.LBB5_9
                                        # -- End function
	.def	initialize_lib;
	.scl	2;
	.type	32;
	.endef
	.globl	initialize_lib                  # -- Begin function initialize_lib
	.p2align	4
initialize_lib:                         # @initialize_lib
# %bb.0:
	pushq	%rbx
	subq	$32, %rsp
	cmpb	$0, _G_initialized(%rip)
	je	.LBB6_1
.LBB6_11:
	movl	$16, %ecx
	callq	lean_alloc_small_object_core
	movl	$1, (%rax)
	movw	$1, 6(%rax)
	movq	$1, 8(%rax)
	jmp	.LBB6_12
.LBB6_1:
	movl	%ecx, %ebx
	movb	$1, _G_initialized(%rip)
	callq	lean_initialize_runtime_module
	movl	%ebx, %ecx
	callq	initialize_Init
	movzbl	7(%rax), %ecx
	shll	$24, %ecx
	cmpl	$16777216, %ecx                 # imm = 0x1000000
	je	.LBB6_12
# %bb.2:
	movl	(%rax), %ecx
	cmpl	$2, %ecx
	jl	.LBB6_4
# %bb.3:
	decl	%ecx
	movl	%ecx, (%rax)
.LBB6_6:
	movl	%ebx, %ecx
	callq	initialize_Init
	movzbl	7(%rax), %ecx
	shll	$24, %ecx
	cmpl	$16777216, %ecx                 # imm = 0x1000000
	jne	.LBB6_7
.LBB6_12:
	addq	$32, %rsp
	popq	%rbx
	retq
.LBB6_7:
	movl	(%rax), %ecx
	cmpl	$2, %ecx
	jl	.LBB6_9
# %bb.8:
	decl	%ecx
	movl	%ecx, (%rax)
	jmp	.LBB6_11
.LBB6_4:
	testl	%ecx, %ecx
	je	.LBB6_6
# %bb.5:
	movq	%rax, %rcx
	callq	lean_dec_ref_cold
	jmp	.LBB6_6
.LBB6_9:
	testl	%ecx, %ecx
	je	.LBB6_11
# %bb.10:
	movq	%rax, %rcx
	callq	lean_dec_ref_cold
	jmp	.LBB6_11
                                        # -- End function
	.lcomm	_G_initialized,1                # @_G_initialized
	.section	.rdata,"dr"
.L.str:                                 # @.str
	.asciz	"D:/lean-4.36/lean-4.36.0-windows/include/lean/lean.h"

.L.str.1:                               # @.str.1
	.asciz	"offset >= lean_ctor_num_objs(o) * sizeof(void*)"

.L.str.2:                               # @.str.2
	.asciz	"lean_is_ctor(o)"

	.section	.debug$S,"dr"
	.p2align	2, 0x0
	.long	4                               # Debug section magic
	.long	241
	.long	.Ltmp1-.Ltmp0                   # Subsection size
.Ltmp0:
	.short	.Ltmp3-.Ltmp2                   # Record length
.Ltmp2:
	.short	4353                            # Record kind: S_OBJNAME
	.long	0                               # Signature
	.byte	0                               # Object name
	.p2align	2, 0x0
.Ltmp3:
	.short	.Ltmp5-.Ltmp4                   # Record length
.Ltmp4:
	.short	4412                            # Record kind: S_COMPILE3
	.long	0                               # Flags and language
	.short	208                             # CPUType
	.short	23                              # Frontend version
	.short	1
	.short	1
	.short	0
	.short	23011                           # Backend version
	.short	0
	.short	0
	.short	0
	.asciz	"clang version 23.1.1"          # Null-terminated compiler version string
	.p2align	2, 0x0
.Ltmp5:
.Ltmp1:
	.p2align	2, 0x0
	.addrsig

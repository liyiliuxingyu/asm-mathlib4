# Lean 自己生成的汇编（Lean 4.36.0, x86-64）

## 装了什么

- `D:\lean-4.36\lean-4.36.0-windows`：官方 848 MB Windows 发行包，经 ghproxy.net 分 6 块下载（直连 GitHub 只有 24 KB/s，镜像约 250 KB/s）
- 版本：`Lean (version 4.36.0, x86_64-w64-windows-gnu, commit 611c117)`
- 包里自带 `clang.exe` / `lld.exe` / `libLLVM-23.dll`，Lean → C → 汇编这条链路是完整的

### 一个必须打的补丁

这台机器是 Windows Server 2019，System32 里只有老的 `icuuc.dll` / `icuin.dll`，没有新版的单体 `icu.dll`，
而 `libInit_shared.dll` 静态导入 `icu.dll`，于是 `lean.exe` 一启动就是 `0xC0000135`。

用包里的 `lld` 造了一个只做转发的 `icu.dll`（9 个符号，2 个来自 icuuc、7 个来自 icuin）：

```
lld.exe -flavor link /dll /noentry /machine:x64 /def:icu.def /out:icu.dll dummy.obj
```

## 编译链

```powershell
lean.exe --c=lib.c lib.lean
clang.exe -S -O2 -ffreestanding -I include -I include/clang lib.c -o lib.s
```

输入 `lib.lean`（3 个定义，6 行）→ `lib.c` 3,725 字节 → `lib.s` 565 行 / 11,202 字节。

## 生成的汇编

### `def add3 (x : UInt64) : UInt64 := x * 3 + 1`

```asm
l_add3:
    leaq  (%rcx,%rcx,2), %rax
    incq  %rax
    retq
```

3 条指令。和第二轮手写的 gcd 同一个风格——LLVM 在这里没有可优化空间。

### `def doubleNat (n : Nat) : Nat := n + n`

```asm
l_doubleNat:
    testb $1, %cl          ; lean_is_scalar
    je    .LBB4_3          ; 不是标量 -> bignum 慢路径
    movq  %rcx, %rax
    andq  $-2, %rax        ; lean_unbox
    testq %rcx, %rcx
    js    .LBB4_2
    leaq  1(,%rax,2), %rax ; lean_box(n+n)
    retq
```

标量快路径 6 条指令。`testb $1` / `andq $-2` / `leaq 1(,%rax,2)` 就是 hand-written 版本里
`test cl,1` / `shr` / `lea` 那套标记位约定——编译器用的是同一套 ABI。

### `fib`：171 条指令

递归、标量判断、bignum 分支，以及内联的引用计数：

```asm
    movl  (%rbx), %eax
    cmpl  $2, %eax
    jl    .LBB0_41
    decl  %eax
    movl  %eax, (%rbx)
```

这正是第三轮手写那 105 字节里的 `lean_dec` 热路径：`mov / cmp / jle / sub`。
编译器生成的是读-改-写，我的是 `sub dword [rcx],1`，逻辑完全同构。

## 结论

- 「Lean 的汇编版」不需要重写，它就是 `clang -S` 的输出，质量已经和手写持平；
- 手写汇编唯一还能赢的地方是没有 box / RC / bignum 的边界（第二轮那 25 字节 gcd）；
- 一旦进入 `Nat` 与堆对象，手写版本要复现的就是这 171 条指令加整个运行时。
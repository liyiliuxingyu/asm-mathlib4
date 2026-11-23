# 手写汇编重写 Lean 内核片段 — 总览

目标：不用任何 C/C++ 编译器，用 x86-64 手写汇编实现 Lean 内核里的关键算法，
并以 Lean 自身为 oracle 做差分验证。

## 成果（全部为最近一次完整回归的结果）

| 模块 | 文件 | 体积 | 验证 | 结果 |
|---|---|---|---|---|
| `Nat.gcd` | `gcd.asm` | 25 B | 22 万用例 + 变异测试 | 0 失配 |
| 引用计数 hot path | `lean_rc.asm` | 68 B | 2³² 计数穷举 | 0 失配 |
| 对象生命周期（含 cold path） | `lean_lifecycle.asm` | 105 B | 500 万次随机操作 | 0 失配 |
| level `is_equivalent` | `level/lvl_equiv.asm` | ~3.3 KB | 5 万对 vs `Level.isEquiv` | 0 失配 |
| level `is_geq` | 同上 | — | 5 万对 vs 移植的 `is_geq_core` | 0 失配 |
| level FFI 端到端 | `level/lvl_ffi.dll` | 5,120 B | 5 万对 | 0 失配 |
| Expr 结构相等 | `level/expr.asm` | 805 B | 1000 对 vs `Expr` BEq | 0 失配 |
| Expr 编解码往返 | `level/expr_roundtrip.lean` | — | 500/500 | 通过 |
| beta（instantiate1） | `level/beta.asm` | ~2 KB | 100 对（bvar 0..2） | 0 失配 |
| zeta（letE） | 同上 | — | 100 对 | 0 失配 |
| delta（常量展开） | 同上 | — | 50 对 | 0 失配 |
| substN（多参数替换） | 同上 | — | 50 对 | 0 失配 |
| iota（recursor） | 同上 | — | 合成 rec 表 50 对 | 0 失配 |
| proj（含带参数归纳族） | 同上 | — | 随机 50 对（nparams=1） | 0 失配 |
| whnf（beta/zeta 片段） | asm 单步 + Lean 循环 | — | 50 对 | 0 失配 |

## 关键约束（这台机器）

- 没有 C/C++ 编译器、没有 git、没有 Windows SDK；只有 PowerShell/.NET 与网络。
- Lean 4.36.0 工具链（848 MB）经 ghproxy 分块下载；System32 缺 `icu.dll`，
  用 `lld` 造了一个转发 DLL 才能启动。
- 执行汇编：`nasm -f bin` → `VirtualAlloc(PAGE_EXECUTE_READWRITE)` → 函数指针调用。
- 接进 Lean：`nasm -f win64` → `lld-link /dll /noentry` 造零导入 DLL → `lean --load-dynlib`。

## 复现（在 `asm-toy/level` 目录）

```powershell
# 1) 重建三个 DLL
nasm -f win64 -I . -o lvl_ba.obj lvl_ba.asm; lld -flavor link /dll /noentry /machine:x64 /export:l_lvlEquivBa /out:lvl_ffi.dll lvl_ba.obj
nasm -f win64 -o expr.obj expr.asm;              lld -flavor link /dll /noentry /machine:x64 /export:l_exprEqBa /out:expr_ffi.dll expr.obj
nasm -f win64 -o beta.obj beta.asm;              lld -flavor link /dll /noentry /machine:x64 /export:l_exprBetaBa /export:l_exprBetaBaT /export:l_exprSubstBaT /export:l_exprIotaBaT /export:l_exprProjBaT /export:l_betaByte /export:l_betaRoot /out:beta_ffi.dll beta.obj

# 2) 跑对拍
lean --load-dynlib=lvl_ffi.dll   lvl_ffi.lean      # 5 万对 level
lean --load-dynlib=expr_ffi.dll  expr_ffi3.lean    # 1000 对 Expr
lean --load-dynlib=beta_ffi.dll  beta_general.lean # 100 对 beta
lean --load-dynlib=beta_ffi.dll  zeta_test.lean    # 100 对 zeta
lean --load-dynlib=beta_ffi.dll  substn_test.lean  # 50 对 substN
lean --load-dynlib=beta_ffi.dll  delta_test.lean   # 50 对 delta whnf
lean --load-dynlib=beta_ffi.dll  iota_test.lean    # 50 对 iota
lean --load-dynlib=beta_ffi.dll  proj_test.lean    # 50 对 proj
lean --load-dynlib=beta_ffi.dll  whnf_test.lean    # 50 对 whnf 片段
```

## 踩过的坑（按代价排序）

1. **`.bss` 不在 `-f bin` 产物里**：缓冲区是标签偏移，`VirtualAlloc` 必须多分配并清零。
2. **共享临时缓冲被递归覆盖**：`tmpTerms` 固定 2 项，嵌套递归覆盖外层 → `is_geq` 错 1/50000；改从 arena 分配。
3. **解释器 FFI**：参数/返回值都装箱；`UInt64` 返回不能给标量（会崩）；零参 `opaque` 不可调用；
   纯函数中的 extern 会被重排（`betaRoot 0` 读残值），必须造数据依赖（`betaRoot len`）。
4. **C# 脚手架 `int` 位移按 31 取模**，64 位字段被写重复，白怀疑汇编半天。
5. **替换时不清 subst 会无限递归**：拷贝实参期间必须临时清空替换表。

## 边界

- 所有 oracle 是 Lean 侧 API（`Level.isEquiv`、`Expr` BEq、`Expr.replace`/`subst0`），不是 C++ kernel；
- iota 的 rec 表是合成的，未从 `ConstantInfo.rec` 导出；proj 不校验构造子；
- whnf 的 head 递归仍在 Lean 侧编排，asm 负责单步；delta/iota/proj 的组合归约未做；
- `is_def_eq` 未实现（依赖完整 whnf + 合一 + reducibility hints）。
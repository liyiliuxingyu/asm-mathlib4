# 嵌套 imax：已完成（arena + 地址数组）

`lvl_equiv.asm`（1,969 字节）现在是「列表化」实现，支持 imax 参数是任意 max/imax。

## 结构

- 规范形式 = arena 里一段**连续**的项列表；项 48 字节：`kind|off|a|na|b|nb`
- atom：kind 0/1/2，`a` = id+1；imax：kind 3，`a,na` = lhs 子列表，`b,nb` = rhs 子列表
- `canon(node, off)` 返回 `(指针, 项数)`，只往 arena 尾部追加（`arenaTop`）
- max：每层递归一个地址数组 `scratch[depth][256]`，先把孩子**地址**收集起来，
  `sortAddr` → `dedupeAddr` → `subsumeAddr`，再 `alloc` 连续块并 `copyTerms`
- imax：先 canon 两边，再按 `mk_imax` 的规则化简；不能化简就写成 imax 项，引用两个子列表

关键点：父节点收集的是**地址**，所以子列表里的项不会被误当成父 max 的孩子——
这正是上一版（顺序写、子列表混在父区间里）崩掉的原因。

## 验证

| 语料 | 结果 |
|---|---|
| 原 5 万对（无嵌套 imax） | 0 失配 |
| 新 5 万对（imax 参数可为 max/imax） | 0 失配 |
| Lean FFI 端到端（嵌套语料，`--load-dynlib`） | 0 失配 |

对拍对象仍是 `Level.isEquiv`。语料生成器现在有一半的 imax 用任意子树做参数。

## 仍然排除

- `succ` 直接套在 imax 上：Lean 自己的 `normalize` 在这里不完备（`addOffset` 后不再归一化），
  汇编做完整归一化，所以这类输入会判得比 Lean 更激进；语料避开了这个形态。
- 哈希 consing：内核里 `lhs == rhs` 是指针相等，这里是结构比较。

## 文件

- `lvl_equiv.asm` —— 新实现（1,969 字节）
- `lvl_equiv_flat.asm` —— 上一版（扁平列表，1,378 字节）备份
- `run_tree2.ps1` —— 汇编 + C# 对拍
- `lvl_ffi.lean` —— Lean 端 5 万对端到端
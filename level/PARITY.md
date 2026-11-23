# level 归一化：与 Lean 完全同构（含 Lean 自身的不完备行为）

## 现在的状态

`lvl_equiv.asm`（2,144 字节）在**完整 Level 文法**上与 `Level.isEquiv` 逐条一致：

| 语料 | 结果 |
|---|---|
| 5 万对（含 `succ` 直接套 max/imax、嵌套 imax、mvar、显式宇宙） | **0 失配** |
| Lean FFI 端到端（同一语料，`--load-dynlib`） | **0 失配** |

## 这轮新增的东西：kind 4「移位 max」

Lean 的 `normalize` 在 imax 退化成 max 时是这么写的：

```lean
| imax l₁ l₂ => if l₂.isNeverZero then addOffset (normalize (mkLevelMax l₁ l₂)) k
```

`addOffset` 只是把 `succ` 包在外面，**不会重新归一化**。所以 `succ (imax p1 p2)` 得到的是
`succ (max p1 p2)` 这种非规范形式，而 `succ (max p1 p2)` 会被分配成 `max (succ p1) (succ p2)`。
两者在 Lean 里**判不等价**——这是它的不完备，不是数学错误。

要在对拍里覆盖这类输入，汇编就必须复现这个「不重新归一化」的行为，于是加了：

- 项 kind 4：`off` + 子列表指针/项数，表示 `succ^k(max ...)` 这种未展开形式
- imax 退化时：先建列表（不加 k），只有 k>0 且项数>1 才包成 kind 4；k=0 直接返回列表
- `cmpTerm` / `sameKey` 对 kind 4 比较 off 和子列表

于是 `succ (imax p1 (succ p2))` 与 `succ (max p1 (succ p2))` 在汇编里也判不等价，与 Lean 一致。

## 验证细节

- 语料生成器现在会随机产生 `S<term>`、`I(term,term)`、`M(term,term)`、`mvar`、`0`、`succ^k(param)`
- 汇编侧：C# 宿主建树直接调 `lvl_equiv`
- Lean 侧：`Level.isEquiv` 判同一份 `pairs.txt`
- FFI 侧：Lean 编码 ByteArray → `@[extern]` → 汇编 → 与 `Level.isEquiv` 比对

## 边界（仍然成立）

1. oracle 是 Lean 侧 `Level.isEquiv`（`src/Lean/Level.lean:409`），不是 C++ kernel 的 `is_equivalent`；
   两者算法同构，但没有直接对 C++ 版本验证过。
2. 内核里 `lhs == rhs` 走的是哈希 consing 的指针相等；这里做的是结构比较，对规范树等价。
3. `is_equivalent` 之外的 level 操作（`is_geq`、`normalize` 的 hash consing、`level_manager`）没有重写。
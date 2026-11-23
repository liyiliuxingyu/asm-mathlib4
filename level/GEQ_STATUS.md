# is_geq：0 失配（问题已解决）

## 那个 bug

`geqTerm` 的「偏移相等且 >0 → 递归 base」分支，会把两个项拷贝到 `.bss` 里的 `tmpTerms`
（固定 2 项）再清零 off 递归。递归进去后如果又走到同一个分支，会**覆盖外层还在用的那两个项**——
`b` 指针正好指向 `tmpTerms+48`，被覆盖后比较结果就错了。

改成从 arena 分配临时项（只增不减，不会重用）后归零。

定位过程用的是新加的钩子：

- `lvl_bt_levels(l1, l2)`：canon 后直接调 `geqTerm` → 确认问题在 `geqTerm` 内部
- `lvl_cmp_levels(l1, l2)`：只调 `cmpTerm` → 排除“相等误判”
- 把 `.nx` 分支临时改成 `jmp .false` → 同一输入从 1 变 0，锁定就是这条递归

## 最终结果

| 检查 | 结果 |
|---|---|
| `lvl_equiv` 5 万对（C# 直接调用） | **0 失配** |
| `lvl_geq` 5 万对 | **0 失配** |
| `lvl_equiv` Lean FFI 端到端 5 万对 | **0 失配** |

汇编 3,3xx 字节；DLL 5,120 字节。

## 现在的覆盖

- `is_equivalent`、`is_geq` 均与 Lean 侧（`Level.isEquiv` / 按 `level.cpp` 移植的 `isGeqCore`）
  在 5 万对随机语料上完全一致；
- 语料含全部六种构造子、嵌套 imax、`succ` 套 max/imax、显式宇宙包含。
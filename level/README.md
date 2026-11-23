# level::is_equivalent 的归一化切片：zero / succ / param / mvar / max / imax

## 现状

Lean 的 `Level` 有六种构造子：`zero` / `succ` / `param` / `mvar` / `max` / `imax`。
这一轮的汇编覆盖了全部六种（参数层面仍有非规范形式的下述限制）。

| 源码 | 作用 |
|---|---|
| `level.cpp:478` | `is_equivalent = lhs == rhs \|\| normalize(lhs) == normalize(rhs)` |
| `level.cpp:414-476` | `normalize`：max 摊平、succ 折 offset、排序、显式宇宙包含 |
| `level.cpp:105-116` | `mk_imax` 化简 |
| `level.cpp:149-161` | `is_not_zero` |
| `Lean/Level.lean:381-410` | oracle |

## mvar 的处理

mvar 与 param 同构，只是原子种类不同：

- 排序次序按 `ctorToNat`：zero(0) < param(1) < mvar(2) < imax(3)
- `is_not_zero mvar = false`、`is_zero mvar = false`、`is_one mvar = false`，所以 imax 里它永远不触发化简
- imax 原子的两个参数各带一个种类，打包成 `(kind << 32) | (id + 1)` 存在 `a` / `b` 里

## 汇编

`lvl_equiv.asm`：**1,378 字节**，项 40 字节（`kind/off/a/oa/b`），
函数 `canon` → `sort` → `dedupe` → `subsume` → 逐项比较。

## 对拍

```
compared: 50000  mismatches: 0  asmTrue=25136  leanTrue=25136
```

语料：一半构造性正例（交换/结合/幂等/`succ` 分配/`max 0 a`/显式宇宙被吸收/`imax` 四条化简），
一半随机树（叶子随机取 `0`、`S^k param`、`S^k mvar`，节点随机 `max` / `imax`）。

## 仍然排除的形态

1. **`succ` 直接套在 imax 上** —— Lean 自己的 `normalize` 在这里不完备
   （imax 转 max 后用 `addOffset` 包 succ 就返回，不再归一化），见 `probe.lean`。
   汇编做的是完整归一化，所以会与 Lean 判不同；这是已知且已记录的差异。
2. imax 的参数本身是 max 或 imax（嵌套非规范形态）
3. 哈希 consing：内核里 `lhs == rhs` 是指针相等
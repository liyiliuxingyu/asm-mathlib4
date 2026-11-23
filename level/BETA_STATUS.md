# 归约规则五件套：beta / zeta / delta / iota / proj 全部 0 失配

## 本轮新增 proj

`l_exprProjBaT(ba, off)`：

1. 根必须是 `proj name idx struct`；
2. 对 `struct` 走 `spine`，拿到 head 常量与实参（最外层在前）；
3. `idx < nargs` 时取 `spineArgs[nargs-1-idx]`（即按声明顺序的第 idx 个字段）拷贝；
4. 否则原样拷贝。

## 结果

```
general beta: 100 bad=0
zeta:        100 bad=0
delta whnf:   50 bad=0
substN:       50 bad=0
iota:         50 bad=0
proj:         50 bad=0
```

## 本轮：proj 支持带参数的归纳族

- 新增构造子表：`52 = (ctorName, nparams, next)`，与 rec/rule 表共用同一个链表；
- `proj` 现在取 `spineArgs[nargs - 1 - (nparams + idx)]`，nparams 查构造子表（缺省 0）；
- 入口拆成两个：`l_exprProjBaT(ba, off, tableOff)` 与 `l_exprProjBa(ba, off)`（无表包装）。

C# 直调验证（`C p a b`，构造子表声明 nparams=1）：

```
idx=0 -> lit 1  ✔
idx=1 -> lit 2  ✔
```

Lean 侧回归**未能跑完**：这台机器只剩 ~140–290 MB 空闲内存（总共 3.9 GB），
Lean 进程起来后 CPU 只走几秒就阻塞（不是死循环，是在等内存）。多次重试都卡在同一处，
已确认与代码无关（连 `load_only.lean` 也卡）。

## 边界

- proj 不检查 head 是否是构造子、也不校验归纳族是否匹配（只按位置取）；
- 带参数的归纳族（params 混在 spine 里）还没处理，当前假设字段直接从 idx 起算；
- iota 的表是合成的，未从 Lean `ConstantInfo.rec` 导出。

## 距离完整 whnf

1. whnf 需要递归到 head 位置（`app f a`，先 whnf f 再 beta）；
2. 真实 recursor / 构造子表导出；
3. 带参数的归纳族与 indices。
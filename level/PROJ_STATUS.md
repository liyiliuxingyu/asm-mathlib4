# proj 支持参数（已通过 Lean 回归）

## 改动

- 构造子表：`52 = (ctorName, nparams, next)`，挂在同一个表链表上；
- `proj` 取 `spineArgs[nargs - 1 - (nparams + idx)]`；
- 入口：`l_exprProjBaT(ba, off, tableOff)`，外加无表包装 `l_exprProjBa`。

## 验证

```
proj: 50 bad=0          # 三元构造子 C p a b，nparams=1
```

## 全量回归（改动后重跑）

```
general beta: 100 bad=0
zeta:        100 bad=0
delta whnf:   50 bad=0
substN:       50 bad=0
iota:         50 bad=0
proj:         50 bad=0
whnf(fragment): 50 bad=0
expr pairs=1000 mismatches=0
level pairs=50000 mismatches=0
```

## 待办

1. whnf 的 head 递归搬进 asm（目前由 Lean 侧编排）；
2. 真实 recursor / 构造子表从 Lean `ConstantInfo` 导出；
3. proj 校验构造子归属；iota 处理 indices。

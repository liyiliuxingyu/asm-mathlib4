# Expr 切片：结构相等 v3 + 编解码往返

## v3（本轮）

- `const` 的 universe 列表：链表节点 30=cons / 31=nil，`leqList` 递归比较，
  每个元素是 `sort` 用的同一套 level 子树（tag 20–25）
- 结果：`expr pairs=1000 mismatches=0`（含带 universe 的 const）

汇编 `expr.asm` 805 字节。

## 编解码往返（为 whnf/beta 铺路）

`expr_roundtrip.lean` 实现了 `enc` 的反向 `dec`（ByteArray → Expr）：

```
roundtrip pairs=500 bad=0
```

即：编码是无损的，asm 只要把变换后的树写进输出缓冲，Lean 就能解回 `Expr` 比较。
这是做 beta/whnf 的前置条件（asm 需要“产生新表达式”，而不只是回答 true/false）。

## (2) whnf 的现状

**未实现 beta**。需要的组件已经清楚：

1. asm 侧输出缓冲 + 偏移重写（拷贝树时重新编号子节点偏移）
2. 受限 beta：`app (lam t body) arg`，其中 `body` 只含 `bvar 0`、`arg` 闭合——
   无需 de Bruijn 移位，直接替换即可；这是能在一轮内验证的最小切片
3. 一般 beta 需要 `instantiate`（移位 + 替换），再往上才是 zeta/delta/iota

## (3) is_def_eq

依赖 (2) 的 whnf 与合一（`is_def_eq_core` 的 binder 处理、`approx` 深度控制、
`reducibility_hints`、congr 回溯）。按 `src/kernel/type_checker.cpp` 的量级是数千行 C++，
不是一轮能交付的东西。
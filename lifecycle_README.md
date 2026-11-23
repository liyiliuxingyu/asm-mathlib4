# Lean 对象生命周期：cold path + 完整回收，用汇编重写

## 对照源码

- `src/include/lean/lean.h:734-750` —— `lean_inc` / `lean_dec`
- `src/runtime/object.cpp:472` —— `lean_dec_ref_cold`
- `src/runtime/object.cpp:483` —— `lean_del_core` 的释放级联（demo 里由宿主的 free 回调代替）

## 汇编

`lean_lifecycle.asm`，三段共 105 字节：

| | 字节 | 作用 |
|---|---|---|
| `lean_inc_asm` | 37 | 标量跳过 / 单线程 ++ / sticky 冻结 / 多线程 `lock sub` |
| `lean_dec_asm` | 27 | rc>1 内联 --，否则跳 cold |
| `lean_dec_ref_cold_asm` | 41 | rc==1 释放；persistent 与 sticky 不动；多线程 `lock xadd` 到 -1 才释放 |

cold path 末尾是 `jmp free_cb`（尾调用），宿主回调负责真正的释放和子对象的 dec 级联 —— 对应 C++ 里的 `lean_del_core`。

## 验证：不变式 + 随机操作

固定拓扑：`2→3→…→23` 的链，外加 `0→2`、`1→2` 两条边（节点 2 有两个父亲，构成共享 DAG）。
5,000,000 次随机 inc / dec，每次检查三条不变式：

1. **不允许重复释放**（同一个节点不能进 free 回调两次）
2. **不允许在还有活着的父亲时释放**（否则父指针悬空）
3. **不允许在自己还持有引用时释放**（`owned != 0`）

收尾时释放所有自有引用，要求 24/24 全部回收。

结果：

```
ops:            5000000
frees during:   9
frees total:    24 / 24   (no leak)
misses:         0
```

## 没覆盖的部分

- 真正的 `lean_del_core`（按对象 tag 分发到 ctor/array/closure/mpz 各自的析构）没有实现，
  释放动作委托给宿主回调；回调只处理"一个子指针"，不是真实的对象图。
- compact region、mimalloc、deletion list 都没有。
- 多线程路径只在单线程下验证了值转移，没有并发压力。

## 复现

```powershell
.\run_lifecycle.ps1 -Ops 5000000
```

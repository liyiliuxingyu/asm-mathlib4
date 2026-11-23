# FFI：Lean 调用手写汇编（已打通）

## 结果

```
pairs=50000 mismatches=0
```

`lean --load-dynlib=lvl_ffi.dll lvl_ffi.lean`：Lean 解析 5 万对 level，
把每对编码成 24 字节节点的 ByteArray，通过 `@[extern]` 调用汇编，
再与 `Level.isEquiv` 逐条比对——全部一致。

## 踩过的三个坑

**1. 解释器只调用有参数的 extern。** `src/runtime/apply.cpp:100` 的 `curry` 里 `case 0: lean_unreachable()`，
零参数探针拿到的根本不是函数返回值（打印出 `0x2AB8`，正好是 `mov eax, imm32` 的操作码）。

**2. 参数和返回值都是装箱的。** `ir_interpreter.cpp:1108-1140`：参数先 `box_t`，返回值若是标量类型
再 `unbox_t`。所以汇编侧要对 `UInt32` 参数做 `shr 1`，对 `Bool` 结果返回 `lean_box(r) = (r<<1)|1`。

**3. ByteArray 的数据在对象 +24 处**（不是 +8 也不是 +16）。用探针逐字节试出来的：
对 `#[0x11,0x22,0x33,0x44]`，`[rcx+8] = [rcx+16] = 4`（长度），`[rcx+24] = 0x11`（首字节）。

## 节点编码

Lean 侧把 level 编码成 24 字节节点（`kind/a/b`），子节点字段存**相对 data 的偏移**；
汇编侧新增一个 `baseVal`，`canon` 每次读子节点时加上它——偏移模式与原来的指针模式（`baseVal = 0`）共用同一份代码。

| kind | 含义 |
|---|---|
| 1 | zero |
| 2 | succ（a = 子偏移） |
| 3 | max（a, b） |
| 4 | param（a = id+1） |
| 5 | imax（a, b） |
| 6 | mvar（a = id+1） |

## 仍然不支持

imax 的参数本身是 max 或 imax（嵌套非规范形态）。当前实现把参数当作原子处理，
这类输入会读错——语料里没有这类形态。要支持它需要把「扁平项列表」换成「规范树」
（节点 arena + 结构比较），是重写而不是补丁。
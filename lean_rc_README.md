# Lean 运行时的引用计数，用汇编重写（68 字节）

## 出处

逐行对照下载下来的 Lean 4.36 源码：

- `src/include/lean/lean.h:734-750` —— `lean_inc_ref` / `lean_inc` / `lean_dec` / `lean_dec_ref`
- `src/include/lean/lean.h:179-184` —— 对象头布局
- `src/include/lean/lean.h:659-699` —— sticky 区阈值的注释（为什么溢出要"冻结"）

```c
typedef struct { int m_rc; unsigned m_cs_sz:16; unsigned m_other:8; unsigned m_tag:8; } lean_object;

static inline void lean_inc(lean_object * o) { if (!lean_is_scalar(o)) lean_inc_ref(o); }
static inline void lean_dec(lean_object * o) { if (!lean_is_scalar(o)) lean_dec_ref(o); }

// 语义：m_rc > 0 单线程；== 0 持久化（不计数）；< 0 多线程（计数为负）
// 溢出/下溢落进 [INT_MIN, INT_MIN+0x20000000) 后对象冻结
```

## 手写结果

`lean_inc_asm` 37 字节：

```
F6 C1 01             test    cl, 1            ; lean_is_scalar
75 1D                jnz     .noop
8B 01                mov     eax, [rcx]       ; m_rc
85 C0                test    eax, eax
7F 11                jg      .st
3D 00 00 00 90       cmp     eax, 0x90000000  ; LEAN_RC_STICKY，无符号比较
76 10                jbe     .noop            ; persistent 或 sticky：不动
F0 83 29 01          lock sub dword [rcx], 1  ; 多线程计数是负的，inc 反而减
B8 02 00 00 00 C3    mov eax,2; ret
83 01 01             add     dword [rcx], 1   ; 无符号回绕，溢出落进 sticky
31 C0 C3             xor eax,eax; ret
31 C0 C3             .noop: xor eax,eax; ret
```

`lean_dec_asm` 31 字节：`test cl,1` → `mov eax,[rcx]` → `cmp eax,1` → `jle` 走 `rc<=1` 分支（`rc==0` 什么都不做；否则返回 1 表示必须走 cold path）→ 否则 `sub dword [rcx],1`。

## 验证

- **穷举**：把 32 位计数从 `0x00000000` 到 `0xFFFFFFFF` 全跑一遍，两个函数各一次，
  每次同时校验「内存里的新 rc」和「返回的状态码」，并检查偏移 4..7 的 `m_cs_sz/m_other/m_tag` 三个字节没被踩坏。
- 结果：**4,294,967,296 个计数 × 2 个函数 = 8.59e9 次校验，0 失配，246 秒**（单线程顺序执行）。
- 标量指针（奇数地址）单独测：`0x3`、`0x101`、`0x7` 全部原样返回 0，不解引用。

## 没覆盖的部分（说清楚）

1. **cold path**：`rc==1` 时真正释放对象在 `src/runtime/object.cpp:472` 的 `lean_dec_ref_cold`，
   涉及释放链表、compact region、mimalloc —— 这个 demo 里只返回状态码 1，不实现释放。
2. **并发**：`lock sub` 的原子性没有被测；我只验证了单线程下的值转移。
3. **模型同源**：C# 里的对照模型是从同一份 `lean.h` 读出来的，所以它不能发现"我读错了源码"这类错误，
   只能发现"汇编没按我读到的语义执行"。真正的 oracle 是 `tests/verif/Verif/runtime/RC.lean`
   —— Lean 项目自己把这段语义形式化成了 `incRefN` / `decRef` 并证明了 `incRefN_spec`。

## 复现

```powershell
.\run_rc.ps1 -Limit 4294967296      # 约 4 分钟
```

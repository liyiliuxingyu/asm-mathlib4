import Init

/-- 结构递归，Lean 能自动证明终止 -/
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

/-- 定宽整数，看 Lean 怎么处理 unboxed 标量 -/
def add3 (x : UInt64) : UInt64 := x * 3 + 1

/-- Nat 上的小函数：每一步都要走 bignum 路径 -/
def doubleNat (n : Nat) : Nat := n + n

def main : IO Unit :=
  IO.println s!"fib 20 = {fib 20}, add3 5 = {add3 5}, double 7 = {doubleNat 7}"

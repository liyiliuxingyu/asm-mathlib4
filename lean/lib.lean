def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

def add3 (x : UInt64) : UInt64 := x * 3 + 1

def doubleNat (n : Nat) : Nat := n + n

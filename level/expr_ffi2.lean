import Lean
open Lean

@[extern "exprEqBa"] opaque exprEqBa (ba : ByteArray) (offA offB : UInt32) : Bool

def putU64 (b : Array UInt8) (x : UInt64) : Array UInt8 :=
  let byte (s : UInt64) : UInt8 := UInt8.ofNat ((x >>> s) &&& 0xFF).toNat
  b.push (byte 0) |>.push (byte 8) |>.push (byte 16) |>.push (byte 24)
   |>.push (byte 32) |>.push (byte 40) |>.push (byte 48) |>.push (byte 56)

def mkENode (b : Array UInt8) (tag a bb c : UInt64) : Array UInt8 :=
  putU64 (putU64 (putU64 (putU64 b tag) a) bb) c

def nameId (n : Name) : Nat :=
  (n.toString.drop 1).foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0

def biNat : BinderInfo → Nat
  | .default => 0
  | .implicit => 1
  | .strictImplicit => 2
  | .instImplicit => 3

partial def encL (buf : Array UInt8) (l : Level) : Array UInt8 × Nat :=
  match l with
  | .zero => (mkENode buf 20 0 0 0, buf.size)
  | .param n => (mkENode buf 24 (nameId n).toUInt64 0 0, buf.size)
  | .mvar m => (mkENode buf 25 (nameId m.name).toUInt64 0 0, buf.size)
  | .succ c =>
    let (b1, o1) := encL buf c
    (mkENode b1 21 (UInt64.ofNat o1) 0 0, b1.size)
  | .max a b =>
    let (b1, o1) := encL buf a
    let (b2, o2) := encL b1 b
    (mkENode b2 22 (UInt64.ofNat o1) (UInt64.ofNat o2) 0, b2.size)
  | .imax a b =>
    let (b1, o1) := encL buf a
    let (b2, o2) := encL b1 b
    (mkENode b2 23 (UInt64.ofNat o1) (UInt64.ofNat o2) 0, b2.size)

partial def enc (buf : Array UInt8) (e : Expr) : Array UInt8 × Nat :=
  match e with
  | .bvar i => (mkENode buf 1 i.toUInt64 0 0, buf.size)
  | .fvar id => (mkENode buf 2 (nameId id.name).toUInt64 0 0, buf.size)
  | .mvar id => (mkENode buf 3 (nameId id.name).toUInt64 0 0, buf.size)
  | .const n _ => (mkENode buf 4 (nameId n).toUInt64 0 0, buf.size)
  | .lit (.natVal v) => (mkENode buf 9 v.toUInt64 0 0, buf.size)
  | .sort l =>
    let (b1, o1) := encL buf l
    (mkENode b1 10 (UInt64.ofNat o1) 0 0, b1.size)
  | .proj n i s =>
    let (b1, o1) := enc buf s
    (mkENode b1 11 (nameId n).toUInt64 (UInt64.ofNat i) (UInt64.ofNat o1), b1.size)
  | .app f a =>
    let (b1, o1) := enc buf f
    let (b2, o2) := enc b1 a
    (mkENode b2 5 (UInt64.ofNat o1) (UInt64.ofNat o2) 0, b2.size)
  | .lam _ t bd bi =>
    let (b1, o1) := enc buf t
    let (b2, o2) := enc b1 bd
    (mkENode b2 6 (UInt64.ofNat o1) (UInt64.ofNat o2) (biNat bi).toUInt64, b2.size)
  | .forallE _ t bd bi =>
    let (b1, o1) := enc buf t
    let (b2, o2) := enc b1 bd
    (mkENode b2 7 (UInt64.ofNat o1) (UInt64.ofNat o2) (biNat bi).toUInt64, b2.size)
  | .letE _ t v bd _ =>
    let (b1, o1) := enc buf t
    let (b2, o2) := enc b1 v
    let (b3, o3) := enc b2 bd
    (mkENode b3 8 (UInt64.ofNat o1) (UInt64.ofNat o2) (UInt64.ofNat o3), b3.size)
  | _ => (mkENode buf 0 0 0 0, buf.size)

structure St where v : UInt64

def nxt (s : St) : Nat × St :=
  let v := s.v * 6364136223846793005 + 1442695040888963407
  ((v >>> 33).toNat, { v := v })

def pick (s : St) (n : Nat) : Nat × St :=
  let (x, s') := nxt s
  (x % n, s')

def biOf : Nat → BinderInfo
  | 0 => .default
  | 1 => .implicit
  | 2 => .strictImplicit
  | _ => .instImplicit

def mkName (i : Nat) : Name := Name.mkSimple s!"n{i}"

def genLevel (s : St) : Level × St :=
  let (k, s1) := pick s 5
  match k with
  | 0 => (Level.zero, s1)
  | 1 => (Level.succ Level.zero, s1)
  | 2 => (Level.param (mkName 1), s1)
  | 3 => (Level.max (Level.param (mkName 1)) Level.zero, s1)
  | _ => (Level.imax (Level.param (mkName 2)) (Level.succ (Level.param (mkName 1))), s1)

partial def gen (depth : Nat) (s : St) : Expr × St :=
  let (c, s1) := if depth = 0 then (0, s) else pick s 9
  if c = 0 then
    let (k, s2) := pick s1 3
    match k with
    | 0 => (Expr.bvar 0, s2)
    | 1 => (Expr.const (mkName (k - 1)) [], s2)
    | _ => (Expr.lit (.natVal (k - 1)), s2)
  else if c = 1 then
    let (a, s2) := gen (depth - 1) s1
    let (b, s3) := gen (depth - 1) s2
    (Expr.app a b, s3)
  else if c = 2 then
    let (t, s2) := gen (depth - 1) s1
    let (b, s3) := gen (depth - 1) s2
    let (i, s4) := pick s3 4
    (Expr.lam (mkName 0) t b (biOf i), s4)
  else if c = 3 then
    let (t, s2) := gen (depth - 1) s1
    let (b, s3) := gen (depth - 1) s2
    let (i, s4) := pick s3 4
    (Expr.forallE (mkName 0) t b (biOf i), s4)
  else if c = 4 then
    let (t, s2) := gen (depth - 1) s1
    let (v, s3) := gen (depth - 1) s2
    let (b, s4) := gen (depth - 1) s3
    (Expr.letE (mkName 0) t v b false, s4)
  else if c = 5 then
    let (l, s2) := genLevel s1
    (Expr.sort l, s2)
  else if c = 6 then
    let (k, s2) := pick s1 2
    if k = 0 then (Expr.fvar ⟨mkName 0⟩, s2) else (Expr.mvar ⟨mkName 1⟩, s2)
  else if c = 7 then
    let (st, s2) := gen (depth - 1) s1
    (Expr.proj (mkName 2) 0 st, s2)
  else
    let (a, s2) := gen (depth - 1) s1
    (a, s2)

def asmEq (a b : Expr) : Bool :=
  let (buf1, oa) := enc #[] a
  let (buf2, ob) := enc buf1 b
  exprEqBa (ByteArray.mk buf2) (UInt32.ofNat oa) (UInt32.ofNat ob)

def main : IO Unit := do
  let mut s : St := { v := 987654321 }
  let mut n := 0
  let mut mism := 0
  let mut first := ""
  for _ in [0:1000] do
    let (e1, s1) := gen 4 s
    let (e2, s2) := gen 4 s1
    s := s2
    let (same, s3) := pick s 3
    s := s3
    let e2 := if same = 0 then e1 else e2
    let rAsm := asmEq e1 e2
    let rLean := e1 == e2
    n := n + 1
    if rAsm != rLean then
      mism := mism + 1
      if first.isEmpty then first := s!"MISMATCH\n{repr e1}\nVS\n{repr e2}"
  IO.println s!"expr pairs={n} mismatches={mism}"
  if !first.isEmpty then IO.println first

#eval main

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

partial def enc (buf : Array UInt8) (e : Expr) : Array UInt8 × Nat :=
  match e with
  | .bvar i => (mkENode buf 1 i.toUInt64 0 0, buf.size)
  | .const n _ => (mkENode buf 4 (nameId n).toUInt64 0 0, buf.size)
  | .lit (.natVal v) => (mkENode buf 9 v.toUInt64 0 0, buf.size)
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

partial def gen (depth : Nat) (s : St) : Expr × St :=
  let (c, s1) := if depth = 0 then (0, s) else pick s 6
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
  else
    let (a, s2) := gen (depth - 1) s1
    (a, s2)

def asmEq (a b : Expr) : Bool :=
  let (buf1, oa) := enc #[] a
  let (buf2, ob) := enc buf1 b
  exprEqBa (ByteArray.mk buf2) (UInt32.ofNat oa) (UInt32.ofNat ob)

def main : IO Unit := do
  let mut s : St := { v := 12345 }
  let mut n := 0
  let mut mism := 0
  let mut first := ""
  for _ in [0:2000] do
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
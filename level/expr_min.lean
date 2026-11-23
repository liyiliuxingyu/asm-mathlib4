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

def asmEq (a b : Expr) : Bool :=
  let (buf1, oa) := enc #[] a
  let (buf2, ob) := enc buf1 b
  exprEqBa (ByteArray.mk buf2) (UInt32.ofNat oa) (UInt32.ofNat ob)

#eval do
  let e1 : Expr := .bvar 0
  let e2 : Expr := .const (Name.mkSimple "n0") []
  let e3 : Expr := .app (.bvar 0) (.lit (.natVal 1))
  let e4 : Expr := .lam (Name.mkSimple "n0") (.const (Name.mkSimple "n0") []) (.bvar 0) .implicit
  let e5 : Expr := .letE (Name.mkSimple "n0") (.const (Name.mkSimple "n2") []) (.bvar 0) (.lit (.natVal 2)) false
  IO.println s!"bvar   asm={asmEq e1 e1} lean={e1 == e1}"
  IO.println s!"const  asm={asmEq e2 e2} lean={e2 == e2}"
  IO.println s!"app    asm={asmEq e3 e3} lean={e3 == e3}"
  IO.println s!"lam    asm={asmEq e4 e4} lean={e4 == e4}"
  IO.println s!"let    asm={asmEq e5 e5} lean={e5 == e5}"

import Lean
open Lean

def getU64 (b : ByteArray) (i : Nat) : UInt64 :=
  let byte (k : Nat) : UInt64 := (b.get! (i + k)).toUInt64
  byte 0 ||| (byte 1 <<< 8) ||| (byte 2 <<< 16) ||| (byte 3 <<< 24)
  ||| (byte 4 <<< 32) ||| (byte 5 <<< 40) ||| (byte 6 <<< 48) ||| (byte 7 <<< 56)

def putU64 (b : Array UInt8) (x : UInt64) : Array UInt8 :=
  let byte (s : UInt64) : UInt8 := UInt8.ofNat ((x >>> s) &&& 0xFF).toNat
  b.push (byte 0) |>.push (byte 8) |>.push (byte 16) |>.push (byte 24)
   |>.push (byte 32) |>.push (byte 40) |>.push (byte 48) |>.push (byte 56)

def mkENode (b : Array UInt8) (tag a bb c : UInt64) : Array UInt8 :=
  putU64 (putU64 (putU64 (putU64 b tag) a) bb) c

def nameId (n : Name) : Nat :=
  (n.toString.drop 1).foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0

def mkName (i : Nat) : Name := Name.mkSimple s!"n{i}"

def biNat : BinderInfo → Nat
  | .default => 0
  | .implicit => 1
  | .strictImplicit => 2
  | .instImplicit => 3

def biOf : Nat → BinderInfo
  | 0 => .default
  | 1 => .implicit
  | 2 => .strictImplicit
  | _ => .instImplicit

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

partial def encLs (buf : Array UInt8) (us : List Level) : Array UInt8 × Nat :=
  match us with
  | [] => (mkENode buf 31 0 0 0, buf.size)
  | u :: rest =>
    let (b1, o1) := encL buf u
    let (b2, o2) := encLs b1 rest
    (mkENode b2 30 (UInt64.ofNat o1) (UInt64.ofNat o2) 0, b2.size)

partial def enc (buf : Array UInt8) (e : Expr) : Array UInt8 × Nat :=
  match e with
  | .bvar i => (mkENode buf 1 i.toUInt64 0 0, buf.size)
  | .fvar id => (mkENode buf 2 (nameId id.name).toUInt64 0 0, buf.size)
  | .mvar id => (mkENode buf 3 (nameId id.name).toUInt64 0 0, buf.size)
  | .const n us =>
    let (b1, o1) := encLs buf us
    (mkENode b1 4 (nameId n).toUInt64 (UInt64.ofNat o1) 0, b1.size)
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

partial def decL (b : ByteArray) (off : Nat) : Level :=
  match getU64 b off with
  | 20 => .zero
  | 24 => .param (mkName (getU64 b (off + 8)).toNat)
  | 25 => .mvar ⟨mkName (getU64 b (off + 8)).toNat⟩
  | 21 => .succ (decL b (getU64 b (off + 8)).toNat)
  | 22 => .max (decL b (getU64 b (off + 8)).toNat) (decL b (getU64 b (off + 16)).toNat)
  | 23 => .imax (decL b (getU64 b (off + 8)).toNat) (decL b (getU64 b (off + 16)).toNat)
  | _ => .zero

partial def decLs (b : ByteArray) (off : Nat) : List Level :=
  match getU64 b off with
  | 30 => decL b (getU64 b (off + 8)).toNat :: decLs b (getU64 b (off + 16)).toNat
  | _ => []

partial def dec (b : ByteArray) (off : Nat) : Expr :=
  match getU64 b off with
  | 1 => .bvar (getU64 b (off + 8)).toNat
  | 2 => .fvar ⟨mkName (getU64 b (off + 8)).toNat⟩
  | 3 => .mvar ⟨mkName (getU64 b (off + 8)).toNat⟩
  | 4 => .const (mkName (getU64 b (off + 8)).toNat) (decLs b (getU64 b (off + 16)).toNat)
  | 9 => .lit (.natVal (getU64 b (off + 8)).toNat)
  | 10 => .sort (decL b (getU64 b (off + 8)).toNat)
  | 11 => .proj (mkName (getU64 b (off + 8)).toNat) (getU64 b (off + 16)).toNat (dec b (getU64 b (off + 24)).toNat)
  | 5 => .app (dec b (getU64 b (off + 8)).toNat) (dec b (getU64 b (off + 16)).toNat)
  | 6 => .lam (mkName 0) (dec b (getU64 b (off + 8)).toNat) (dec b (getU64 b (off + 16)).toNat) (biOf (getU64 b (off + 24)).toNat)
  | 7 => .forallE (mkName 0) (dec b (getU64 b (off + 8)).toNat) (dec b (getU64 b (off + 16)).toNat) (biOf (getU64 b (off + 24)).toNat)
  | 8 => .letE (mkName 0) (dec b (getU64 b (off + 8)).toNat) (dec b (getU64 b (off + 16)).toNat) (dec b (getU64 b (off + 24)).toNat) false
  | _ => .bvar 999

structure St where
  v : UInt64

def nxt (s : St) : Nat × St :=
  let v := s.v * 6364136223846793005 + 1442695040888963407
  ((v >>> 33).toNat, { v := v })

def pick (s : St) (n : Nat) : Nat × St :=
  let (x, s') := nxt s
  (x % n, s')

def biOfN : Nat → BinderInfo
  | 0 => .default
  | 1 => .implicit
  | 2 => .strictImplicit
  | _ => .instImplicit

def genLevel (s : St) : Level × St :=
  let (k, s1) := pick s 4
  match k with
  | 0 => (Level.zero, s1)
  | 1 => (Level.succ Level.zero, s1)
  | 2 => (Level.param (mkName 1), s1)
  | _ => (Level.max (Level.param (mkName 1)) Level.zero, s1)

partial def hasBv (e : Expr) : Bool :=
  match e with
  | .bvar _ => true
  | .app f a => hasBv f || hasBv a
  | .lam _ t b _ => hasBv t || hasBv b
  | .forallE _ t b _ => hasBv t || hasBv b
  | .letE _ t v b _ => hasBv t || hasBv v || hasBv b
  | .proj _ _ s => hasBv s
  | _ => false

partial def gen (depth : Nat) (s : St) : Expr × St :=
  let (c, s1) := if depth = 0 then (0, s) else pick s 8
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
    (Expr.lam (mkName 0) t b (biOfN i), s4)
  else if c = 3 then
    let (t, s2) := gen (depth - 1) s1
    let (b, s3) := gen (depth - 1) s2
    (Expr.forallE (mkName 0) t b .default, s3)
  else if c = 4 then
    let (a, s2) := gen (depth - 1) s1
    (Expr.proj (mkName 2) 0 a, s2)
  else if c = 5 then
    let (l, s2) := genLevel s1
    (Expr.sort l, s2)
  else
    let (a, s2) := gen (depth - 1) s1
    (a, s2)

partial def genClosed (depth : Nat) (s : St) : Expr × St :=
  let (e, s1) := gen depth s
  if hasBv e then genClosed depth s1 else (e, s1)

@[extern "exprBetaBa"] opaque exprBetaBa (ba : ByteArray) (off : UInt32) : UInt32
@[extern "betaRoot"] opaque betaRoot (x : UInt32) : UInt32
@[extern "betaByte"] opaque betaByte (i : UInt32) : UInt8

def runBeta (e : Expr) : Option Expr := Id.run do
  let (buf, off) := enc #[] e
  let len := (exprBetaBa (ByteArray.mk buf) (UInt32.ofNat off)).toNat
  let root := (betaRoot (UInt32.ofNat len)).toNat
  if len = 0 || len > 60000 then return none
  let mut arr : Array UInt8 := #[]
  for i in [0:len] do
    arr := arr.push (betaByte (UInt32.ofNat i))
  return some (dec (ByteArray.mk arr) root)

def expected (body arg : Expr) : Expr :=
  body.replace (fun e => match e with | .bvar 0 => some arg | _ => none)

partial def subst0 : Expr → Expr → Expr
  | .bvar 0, a => a
  | .bvar (k+1), _ => .bvar k
  | .app f x, a => .app (subst0 f a) (subst0 x a)
  | .lam n t b bi, a => .lam n (subst0 t a) (subst0 b a) bi
  | .forallE n t b bi, a => .forallE n (subst0 t a) (subst0 b a) bi
  | .letE n t v b nd, a => .letE n (subst0 t a) (subst0 v a) (subst0 b a) nd
  | .proj n i s, a => .proj n i (subst0 s a)
  | e, _ => e

structure St2 where
  v : UInt64

def nxt2 (s : St2) : Nat × St2 :=
  let v := s.v * 6364136223846793005 + 1442695040888963407
  ((v >>> 33).toNat, { v := v })

def pick2 (s : St2) (n : Nat) : Nat × St2 :=
  let (x, s') := nxt2 s
  (x % n, s')

partial def genB (depth : Nat) (s : St2) : Expr × St2 :=
  let (c, s1) := if depth = 0 then (0, s) else pick2 s 6
  if c = 0 then
    let (k, s2) := pick2 s1 4
    match k with
    | 0 => (Expr.bvar 0, s2)
    | 1 => (Expr.bvar 1, s2)
    | 2 => (Expr.bvar 2, s2)
    | _ => (Expr.const (mkName 0) [], s2)
  else if c = 1 then
    let (a, s2) := genB (depth - 1) s1
    let (b, s3) := genB (depth - 1) s2
    (Expr.app a b, s3)
  else if c = 2 then
    let (t, s2) := genB (depth - 1) s1
    let (b, s3) := genB (depth - 1) s2
    (Expr.lam (mkName 0) t b .default, s3)
  else if c = 3 then
    let (t, s2) := genB (depth - 1) s1
    let (b, s3) := genB (depth - 1) s2
    (Expr.forallE (mkName 0) t b .default, s3)
  else
    let (a, s2) := genB (depth - 1) s1
    (a, s2)

@[extern "exprProjBaT"] opaque exprProjBaT (ba : ByteArray) (off : UInt32) (tbl : UInt32) : UInt32

def runProj (e : Expr) : Option Expr := Id.run do
  let (b1, o1) := enc #[] e
  let ctorOff := b1.size
  let b2 := putU64 (putU64 (putU64 (putU64 b1 52) 20) 1) 0
  let len := (exprProjBaT (ByteArray.mk b2) (UInt32.ofNat o1) (UInt32.ofNat ctorOff)).toNat
  let root := (betaRoot (UInt32.ofNat len)).toNat
  if len = 0 || len > 60000 then return none
  let mut arr : Array UInt8 := #[]
  for i in [0:len] do arr := arr.push (betaByte (UInt32.ofNat i))
  return some (dec (ByteArray.mk arr) root)

def main : IO Unit := do
  let mut s : St2 := { v := 777001 }
  let mut n := 0
  let mut bad := 0
  let mut first := ""
  for _ in [0:50] do
    let (a, s1) := genB 2 s
    let (b, s2) := genB 2 s1
    let (k, s3) := pick2 s2 2
    s := s3
    let (p0, s4) := genB 1 s3
    s := s4
    let e := Expr.proj (mkName 5) k (Expr.app (Expr.app (Expr.app (Expr.const (mkName 20) []) p0) a) b)
    let exp := if k = 0 then a else b
    match runProj e with
    | some r =>
      n := n + 1
      if r == exp then pure () else
        bad := bad + 1
        if first.isEmpty then first := s!"k={k} got={repr r} exp={repr exp}"
    | none => bad := bad + 1; n := n + 1
  IO.println s!"proj: {n} bad={bad}"
  if !first.isEmpty then IO.println first

#eval main
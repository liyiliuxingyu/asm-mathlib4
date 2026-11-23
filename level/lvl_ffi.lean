import Lean.Level
open Lean

@[extern "lvlEquivBa"] opaque lvlEquivBa (ba : ByteArray) (offA offB : UInt32) : Bool

def putU64 (b : Array UInt8) (x : UInt64) : Array UInt8 :=
  let byte (s : UInt64) : UInt8 := UInt8.ofNat ((x >>> s) &&& 0xFF).toNat
  b.push (byte 0) |>.push (byte 8) |>.push (byte 16) |>.push (byte 24)
   |>.push (byte 32) |>.push (byte 40) |>.push (byte 48) |>.push (byte 56)

def mkNode (b : Array UInt8) (k a bb : UInt64) : Array UInt8 :=
  putU64 (putU64 (putU64 b k) a) bb

def numOfName (n : Name) (pre : String) : Nat :=
  let s := n.toString
  (s.drop pre.length).foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0

partial def build (buf : Array UInt8) (l : Level) : Array UInt8 × Nat :=
  match l with
  | .zero => (mkNode buf 1 0 0, buf.size)
  | .param n => (mkNode buf 4 (UInt64.ofNat (numOfName n "p") + 1) 0, buf.size)
  | .mvar m => (mkNode buf 6 (UInt64.ofNat (numOfName m.name "v") + 1) 0, buf.size)
  | .succ c =>
    let (buf1, co) := build buf c
    (mkNode buf1 2 (UInt64.ofNat co) 0, buf1.size)
  | .max a b =>
    let (buf1, ao) := build buf a
    let (buf2, bo) := build buf1 b
    (mkNode buf2 3 (UInt64.ofNat ao) (UInt64.ofNat bo), buf2.size)
  | .imax a b =>
    let (buf1, ao) := build buf a
    let (buf2, bo) := build buf1 b
    (mkNode buf2 5 (UInt64.ofNat ao) (UInt64.ofNat bo), buf2.size)

def asmEquiv (a b : Level) : Bool :=
  let (buf1, ao) := build #[] a
  let (buf2, bo) := build buf1 b
  lvlEquivBa (ByteArray.mk buf2) (UInt32.ofNat ao) (UInt32.ofNat bo)

partial def readNum (cs : Array Char) (i : Nat) : Nat × Nat :=
  let rec go (i : Nat) (acc : Nat) : Nat × Nat :=
    if h : i < cs.size then
      let c := cs[i]
      if c.isDigit then go (i + 1) (acc * 10 + (c.toNat - '0'.toNat)) else (acc, i)
    else (acc, i)
  go i 0

partial def parse (cs : Array Char) (i : Nat) : Level × Nat :=
  if h : i < cs.size then
    match cs[i] with
    | '0' => (Level.zero, i + 1)
    | 'V' =>
      let (n, j) := readNum cs (i + 1)
      (Level.mvar { name := Name.mkSimple s!"v{n}" }, j)
    | 'P' =>
      let (n, j) := readNum cs (i + 1)
      (Level.param (Name.mkSimple s!"p{n}"), j)
    | 'S' =>
      let (l, j) := parse cs (i + 1)
      (Level.succ l, j)
    | 'I' =>
      let (a, j1) := parse cs (i + 2)
      let (b, j2) := parse cs (j1 + 1)
      (Level.imax a b, j2 + 1)
    | 'M' =>
      let (a, j1) := parse cs (i + 2)
      let (b, j2) := parse cs (j1 + 1)
      (Level.max a b, j2 + 1)
    | _ => (Level.zero, i)
  else (Level.zero, i)

def parseTerm (s : String) : Level := (parse s.toList.toArray 0).1

def main : IO Unit := do
  let txt ← IO.FS.readFile "pairs.txt"
  let lines := (txt.splitOn "\n").filter (fun l => !l.isEmpty) |>.take 50000
  let mut n := 0
  let mut mism := 0
  let mut first := ""
  for line in lines do
    let parts := line.splitOn "|"
    let a := parseTerm parts[0]!
    let b := parseTerm parts[1]!
    let rAsm := asmEquiv a b
    let rLean := Level.isEquiv a b
    n := n + 1
    if rAsm != rLean then
      mism := mism + 1
      if first.isEmpty then first := line
  IO.println s!"pairs={n} mismatches={mism}"
  if !first.isEmpty then IO.println s!"first: {first}"

#eval main

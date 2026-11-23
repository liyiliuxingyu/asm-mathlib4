import Lean.Level
open Lean

partial def isGeqCore (l1 l2 : Level) : Bool :=
  if l1 == l2 then true
  else if l2 == .zero then true
  else
    match l2 with
    | .max a b => isGeqCore l1 a && isGeqCore l1 b
    | _ =>
      if (match l1 with | .max a b => isGeqCore a l2 || isGeqCore b l2 | _ => false) then true
      else match l2 with
        | .imax a b => isGeqCore l1 a && isGeqCore l1 b
        | _ =>
          match l1 with
          | .imax _ b => isGeqCore b l2
          | _ =>
            let p1 := l1.getOffset
            let p2 := l2.getOffset
            let b1 := l1.getLevelOffset
            let b2 := l2.getLevelOffset
            if b1 == b2 || b2 == .zero then p1 >= p2
            else if p1 == p2 && p1 > 0 then isGeqCore b1 b2
            else false

def isGeq (l1 l2 : Level) : Bool := isGeqCore (Level.normalize l1) (Level.normalize l2)

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
  let mut out : Array String := #[]
  for line in lines do
    let parts := line.splitOn "|"
    let a := parseTerm parts[0]!
    let b := parseTerm parts[1]!
    out := out.push (if isGeq a b then "1" else "0")
  IO.FS.writeFile "geq_lean.txt" (String.intercalate "\n" out.toList ++ "\n")
  IO.println s!"geq verdicts: {out.size}"

#eval main
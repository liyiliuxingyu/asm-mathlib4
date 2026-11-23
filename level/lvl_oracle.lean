import Lean.Level

open Lean

partial def readNum (cs : Array Char) (i : Nat) : Nat × Nat :=
  let rec go (i : Nat) (acc : Nat) : Nat × Nat :=
    if h : i < cs.size then
      let c := cs[i]
      if c.isDigit then go (i + 1) (acc * 10 + (c.toNat - '0'.toNat))
      else (acc, i)
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

def parseTerm (s : String) : Level :=
  (parse s.toList.toArray 0).1

def runOracle : IO Unit := do
  let txt ← IO.FS.readFile "pairs.txt"
  let lines := txt.splitOn "\n" |>.filter (fun l => !l.isEmpty)
  let mut out : Array String := #[]
  for line in lines do
    let parts := line.splitOn "|"
    let a := parseTerm parts[0]!
    let b := parseTerm parts[1]!
    out := out.push (if Level.isEquiv a b then "1" else "0")
  IO.FS.writeFile "lean_out.txt" (String.intercalate "\n" out.toList ++ "\n")
  IO.println s!"lean verdicts: {out.size}"

#eval runOracle

import Lean.Level
open Lean

partial def isGeqCore (l1 l2 : Level) : Bool :=
  if l1 == l2 then true
  else if l2 == .zero then true
  else
    match l2 with
    | .max a b => isGeqCore l1 a && isGeqCore l1 b
    | _ =>
      match l1 with
      | .max a b => (isGeqCore a l2 || isGeqCore b l2) || isGeqCoreAux l1 l2
      | _ => isGeqCoreAux l1 l2
where
  isGeqCoreAux (l1 l2 : Level) : Bool :=
    match l2 with
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

def p (n : Nat) : Level := Level.param (Name.mkSimple s!"p{n}")

#eval [isGeq (p 1) (p 1), isGeq (Level.succ (p 1)) (p 1), isGeq (p 1) (Level.succ (p 1)),
       isGeq (Level.max (p 1) (p 2)) (p 1), isGeq (p 1) (Level.max (p 1) (p 2))]

import Lean.Level
open Lean
def p (n : Nat) : Level := Level.param (Name.mkSimple s!"p{n}")
def s := Level.succ
def m := Level.max
def i := Level.imax

def l1 := m (m (i (p 2) (s Level.zero)) (s (p 1))) (s (i (p 2) (s Level.zero)))
def l2 := s (i (s (s (p 2))) (p 3))
#eval repr (Level.normalize l1)
#eval repr (Level.normalize l2)

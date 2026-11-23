import Lean.Level
open Lean
def p (n : Nat) : Level := Level.param (Name.mkSimple s!"p{n}")
def v (n : Nat) : Level := Level.mvar { name := Name.mkSimple s!"v{n}" }
def s := Level.succ
def m := Level.max
def i := Level.imax

def l1 := s (m (i (s (s (v 1))) (s (s (p 3)))) (m (Level.zero) (v 1)))
def l2 := i (p 3) (p 3)
#eval repr (Level.normalize l1)
#eval repr (Level.normalize l2)

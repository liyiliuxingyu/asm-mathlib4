import Lean.Level
open Lean
def p (n : Nat) : Level := Level.param (Name.mkSimple s!"p{n}")
def s := Level.succ
def m := Level.max
def i := Level.imax
#eval [Level.isEquiv (p 1) (p 1),
       Level.isEquiv (s (i (p 1) (p 2))) (s (i (p 2) (p 1))),
       Level.isEquiv (s (i (p 1) (p 2))) (m (s (p 1)) (s (p 2))),
       Level.isEquiv (s (i (p 1) (s (p 2)))) (s (m (p 1) (s (p 2)))),
       Level.isEquiv (m (s (i (p 1) (p 2))) (p 3)) (m (p 3) (s (i (p 2) (p 1))))]

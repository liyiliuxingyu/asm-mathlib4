import Lean.Level
open Lean

def p (n : Nat) : Level := Level.param (Name.mkSimple s!"p{n}")
def s (l : Level) : Level := Level.succ l
def m (a b : Level) : Level := Level.max a b

#eval Level.isEquiv (s (m (p 1) (p 3))) (m (s (p 1)) (s (p 3)))
#eval Level.isEquiv (s (m (p 1) (Level.imax (p 1) (s (s (s (p 3))))))) (m (s (p 1)) (s (Level.imax (p 1) (s (s (s (p 3)))))))
#eval repr (Level.normalize (s (m (p 1) (Level.imax (p 1) (s (s (s (p 3))))))))
#eval repr (Level.normalize (m (s (p 1)) (s (Level.imax (p 1) (s (s (s (p 3))))))))

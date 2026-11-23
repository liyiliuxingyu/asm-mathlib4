import Lean
open Lean

@[extern "betaByte"] opaque betaByte (i : UInt32) : UInt8

#eval do
  IO.println "before betaByte"
  let b := betaByte 0
  IO.println s!"betaByte 0 = {b}"
  IO.println "after"

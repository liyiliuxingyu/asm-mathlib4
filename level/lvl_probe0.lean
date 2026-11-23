import Lean.Level
open Lean

@[extern "lvlProbe0"] opaque lvlProbe0 : UInt32

#eval do
  IO.println s!"probe0 = {lvlProbe0}"

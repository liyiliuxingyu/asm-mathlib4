import Lean.Level
open Lean

@[extern "lvlProbeBa"] opaque lvlProbeBa (ba : ByteArray) (x y : UInt32) : UInt32

#eval do
  let ba : ByteArray := ⟨#[0x11, 0x22, 0x33, 0x44]⟩
  IO.println s!"probe = {lvlProbeBa ba 0 0}"

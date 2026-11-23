import Lean.Level
open Lean

@[extern "lvl_equiv_ba"] opaque lvlEquivBa (ba : ByteArray) (offA offB : UInt32) : UInt8
@[extern "lvl_probe"] opaque lvlProbe (ba : ByteArray) : UInt64

#eval do
  let ba : ByteArray := ⟨#[0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88]⟩
  IO.println s!"probe(+8) = {lvlProbe ba}"

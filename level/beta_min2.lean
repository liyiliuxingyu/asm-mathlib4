import Lean
open Lean

@[extern "betaByte"] opaque betaByte (i : UInt32) : UInt8
@[extern "exprBetaBa"] opaque exprBetaBa (ba : ByteArray) (off : UInt32) : UInt64

def putU64 (b : Array UInt8) (x : UInt64) : Array UInt8 :=
  let byte (s : UInt64) : UInt8 := UInt8.ofNat ((x >>> s) &&& 0xFF).toNat
  b.push (byte 0) |>.push (byte 8) |>.push (byte 16) |>.push (byte 24)
   |>.push (byte 32) |>.push (byte 40) |>.push (byte 48) |>.push (byte 56)

def mkN (b : Array UInt8) (tag a bb c : UInt64) : Array UInt8 :=
  putU64 (putU64 (putU64 (putU64 b tag) a) bb) c

#eval do
  IO.println "A: dll loaded"
  IO.println s!"B: betaByte 0 = {betaByte 0}"
  let buf := mkN #[] 1 0 0 0
  let ba : ByteArray := ByteArray.mk buf
  IO.println s!"C: ba.size = {ba.size}"
  let packed := exprBetaBa ba 0
  IO.println s!"D: packed = {packed}"

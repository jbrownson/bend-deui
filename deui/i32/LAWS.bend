import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I

# What I32 addition promises; PROOF.bend proves it. Coordinates are
# bend-kit-int's I32, which adds as U32 does, wrapping at 2^32.

# LAW: adding in either order gives the same.
law add_comm:
  for a: I.I32
  for b: I.I32
  {(a + b : I.I32) == (b + a : I.I32) : I.I32}

# LAW: adding three, it doesn't matter which two are added first.
law add_assoc:
  for a: I.I32
  for b: I.I32
  for c: I.I32
  {((a + b : I.I32) + c : I.I32) == (a + (b + c : I.I32) : I.I32) : I.I32}

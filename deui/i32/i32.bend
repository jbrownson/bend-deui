import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I

# Whether two coordinates are the same: whether their bits are.
def same(a: I.I32, b: I.I32) -> Bool:
  match a b:
    case I.I32{x} I.I32{y}:
      U32.is_eq(x, y)

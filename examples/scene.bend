import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../deui/scene/scene.bend as S

def n(x: U32) -> I.I32:
  I.I32.from_u32(x)

# A row of the given height and color, at y in its column.
def row(y: U32, h: U32, color: U32) -> S.Scene:
  S.Fill{n(0), n(y), n(100), n(h), color}

# Three rows of 10, stacked.
def column() -> S.Scene:
  S.Group{n(0), n(0), S.chain([row(0, 10, 1), row(10, 10, 2), row(20, 10, 3)])}

# A row of 5 inserted second: the insert, then one Shift moves every row
# below it down by 5.
def main() -> S.Scene:
  S.apply(S.apply(column(), S.Insert{1n, row(10, 5, 9)}), S.Shift{2n, n(0), n(5)})

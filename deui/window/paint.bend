import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../scene/scene.bend as S
import ../../vendor/amage/Chromi/scene.bend as Sc
import ../../vendor/amage/Chromi/geometry.bend as CG

# A scene as a Chromi draw list: each fill, at its offset plus its groups',
# in order, so what's drawn later is on top. Targets aren't drawn. This is
# the part of drawing that runs on every frame; the scene itself is kept,
# and only changes by its edits.

def float(v: I.I32) -> F32:
  +u = I.I32.to_u32(v)
  Bool.pick(F32, U32.is_ge(u, 2147483648), F32.neg(U32.to_f32((0 - u : U32))), U32.to_f32(u))

# A 0xRRGGBB color as Chromi's 0xRRGGBBAA, opaque.
def rgba(+rgb: U32) -> U32:
  ((rgb << 8n) .|. 255 : U32)

# s drawn onto out, its offsets moved by ox and oy.
def paint(s: S.Scene, +ox: I.I32, +oy: I.I32, out: Sc.Scene) -> Sc.Scene:
  match s:
    case S.Fill{x, y, w, h, c}:
      Sc.fill_rect(out, CG.Rect{float((ox + x : I.I32)), float((oy + y : I.I32)), float(w), float(h)}, rgba(c))
    case S.Target{x, y, w, h, t}:
      out
    case S.Group{x, y, cs}:
      paint(cs, (ox + x : I.I32), (oy + y : I.I32), out)
    case S.End{}:
      out
    case S.Child{f, r}:
      paint(r, ox, oy, paint(f, ox, oy, out))

# A frame: the scene on a background of `bg` (0xRRGGBB), width by height.
def frame(s: S.Scene, +width: U32, +height: U32, +bg: U32) -> Sc.Scene:
  paint(s, I.I32{0}, I.I32{0}, Sc.new(width, height, 1.0, rgba(bg)))

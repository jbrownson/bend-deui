import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../scene/scene.bend as S
import ../../vendor/amage/Chromi/scene.bend as Sc
import ../../vendor/amage/Chromi/geometry.bend as CG
import ../../vendor/amage/Runika/font.bend as F
import ../../vendor/amage/Syllo/main.bend as Sy
import ../../vendor/amage/Dithra/main.bend as D
import ../../vendor/amage/Dithra/raster.bend as DR

# A scene as a Chromi draw list: each fill and label, at its offset plus
# its groups', in order, so what's drawn later is on top. Targets aren't
# drawn. Labels are laid out and rasterized here, in the font given; with
# none, they're left out. This is
# the part of drawing that runs on every frame; the scene itself is kept,
# and only changes by its edits.

def float(v: I.I32) -> F32:
  +u = I.I32.to_u32(v)
  Bool.pick(F32, U32.is_ge(u, 2147483648), F32.neg(U32.to_f32((0 - u : U32))), U32.to_f32(u))

# A 0xRRGGBB color as Chromi's 0xRRGGBBAA, opaque.
def rgba(+rgb: U32) -> U32:
  ((rgb << 8n) .|. 255 : U32)

# Text
# ----

# A glyph's key in the GPU's atlas, which keeps one mask per key: its id
# in the font and its size, so each glyph at each size has its own.
def glyph.key(+gid: U32, +size: U32) -> U32:
  (((gid * 512 : U32) + size : U32) + 1 : U32)

# One glyph's coverage, inked at its place from the label's top left.
def glyph(m: D.PositionedMask, out: Sc.Scene, +key: U32, +x: F32, +top: F32, +color: U32) -> Sc.Scene:
  D.PositionedMask{dx, dy, start, end, DR.Mask{w, h, left, otop, adv, data}} = m
  Sc.blit_mask(out, key, (x + dx : F32), (top + dy : F32), w, h, data, color)

def rasterized(r: Result<&2, &2, String, DR.Mask>, out: Sc.Scene, +key: U32, gx: F32, gy: F32, +x: F32, +top: F32, +color: U32) -> Sc.Scene:
  match r:
    case Done{m}:
      glyph(D.position(m, gx, gy, 0, 0), out, key, x, top, color)
    case Fail{e}:
      Sc.reject(out, e)

# A label's glyphs, each rasterized at its place in the layout.
def glyphs(ps: List<&2, Sy.Placement>, +font: F.Font, +size: U32, out: Sc.Scene, +x: F32, +top: F32, +color: U32) -> Sc.Scene:
  match ps:
    case Nil{}:
      out
    case Con{Sy.Placement{+gid, start, end, gx, base, adv, line}, rest}:
      glyphs(rest, font, size, rasterized(D.glyph(font, gid, U32.to_f32(size)), out, glyph.key(gid, size), gx, base, x, top, color), x, top, color)

def laid(+font: F.Font, r: Result<&2, &2, String, Sy.Layout>, +size: U32, out: Sc.Scene, +x: F32, +top: F32, +color: U32) -> Sc.Scene:
  match r:
    case Done{Sy.Layout{ps, width, height, asc, desc, lh, lines}}:
      glyphs(ps, font, size, out, x, top, color)
    case Fail{e}:
      Sc.reject(out, e)

# A label, size pixels tall, in the font if there is one.
def label(font: Maybe<&2, F.Font>, text: String, +size: U32, out: Sc.Scene, +x: F32, +top: F32, +color: U32) -> Sc.Scene:
  match font:
    case Some{+f}:
      laid(f, Sy.layout(f, text, U32.to_f32(size), 100000.0), size, out, x, top, color)
    case None{}:
      out

# The scene
# ---------

# s drawn onto out, its offsets moved by ox and oy.
def paint(s: S.Scene, +font: Maybe<&2, F.Font>, +ox: I.I32, +oy: I.I32, out: Sc.Scene) -> Sc.Scene:
  match s:
    case S.Fill{x, y, w, h, c}:
      Sc.fill_rect(out, CG.Rect{float((ox + x : I.I32)), float((oy + y : I.I32)), float(w), float(h)}, rgba(c))
    case S.Label{x, y, z, c, t}:
      label(font, t, z, out, float((ox + x : I.I32)), float((oy + y : I.I32)), rgba(c))
    case S.Target{x, y, w, h, t}:
      out
    case S.Group{x, y, cs}:
      paint(cs, font, (ox + x : I.I32), (oy + y : I.I32), out)
    case S.End{}:
      out
    case S.Child{f, r}:
      paint(r, font, ox, oy, paint(f, font, ox, oy, out))

# A frame: the scene on a background of `bg` (0xRRGGBB), width by height,
# its labels in the font if there is one.
def frame(s: S.Scene, +font: Maybe<&2, F.Font>, +width: U32, +height: U32, +bg: U32) -> Sc.Scene:
  paint(s, font, I.I32{0}, I.I32{0}, Sc.new(width, height, 1.0, rgba(bg)))

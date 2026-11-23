import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../scene/scene.bend as S

# The screen: a window, its events, and drawing a scene in it. screen.c
# does it natively with SDL3 and SDL3_ttf. Objects cross as U32 ids, and
# failures as Fail{(code, text)}.
#
# Events come as one list of words per event: its kind, then its fields.
# Coordinates are F32's bits, times milliseconds.
#   1 x y time button down   a mouse button, W3C's numbering, down 1 or 0
#   2 x y time               the mouse moved
#   3 code down              a key, Base's code
#   4 c c ...                text typed, as code points
#   5 x y dx dy              the wheel, under (x, y)
#   6                        the window asked to close
#   7                        the mouse left the window
#   8 on                     the window gained (1) or lost (0) the focus
#
# The screen keeps a copy of the scene, set once, then changed only by the
# scene's edits, as S.apply makes them. Both cross as words, coordinates as
# I32's bits, colors 0xRRGGBB, positions as U32.
#   a scene:  1 x y w h color           Fill
#             2 x y size color c ... 0  Label, its text's code points
#             3                         Target, which isn't drawn
#             4 x y <scene>             Group, and its children
#             5                         End
#             6 <scene> <scene>         Child, first and rest
#   an edit:  1 dx dy                   Translate
#             2 at <scene>              Insert
#             3 at                      Delete
#             4 at <edit>               Update
#             5 from dx dy              Shift

# The effects
# -----------

# A window of the given size, with its title.
def screen_open(title: String, width: U32, height: U32) -> IO(Result<&1, &1, U32 & String, U32>):
  import "./screen.c"

# The TrueType font labels are drawn in.
def screen_font(window: U32, path: String) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./screen.c"

# The events that came, waiting up to ms milliseconds for the first
# (4294967295: for as long as it takes); each is a list of words.
def screen_wait(window: U32, ms: U32) -> IO(Result<&1, &1, U32 & String, List<&2, List<&2, U32>>>):
  import "./screen.c"

# Sets the scene the screen keeps.
def screen_scene(window: U32, scene: List<&2, U32>) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./screen.c"

# Applies a run of edits to the scene the screen keeps.
def screen_edit(window: U32, edits: List<&2, U32>) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./screen.c"

# Draws the scene the screen keeps on a background of 0xRRGGBB, and shows
# it.
def screen_draw(window: U32, background: U32) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./screen.c"

def screen_close(window: U32) -> IO(Result<&1, &1, U32 & String, Unit>):
  import "./screen.c"

# Events
# ------

# An F32, from its bits.
def float(u: U32) -> F32:
  match u:
    case U32{w}:
      F32{w}

def word(+ws: List<&2, U32>, i: Nat) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, ws, i), 0)

# Code points as a String.
def text(ws: List<&2, U32>) -> String:
  match ws:
    case Nil{}:
      SNil{}
    case Con{c, rest}:
      SCon{Chr{c}, text(rest)}

def down(+u: U32) -> Bool:
  U32.is_ne(u, 0)

# The event of a kind, from its fields. The mouse is pointer 0.
def event.of(kind: Nat, +fs: List<&2, U32>) -> Maybe<&2, Event>:
  match kind:
    case 1n:
      Some{Press{0, Tool.Mouse{}, float(word(fs, 0n)), float(word(fs, 1n)), word(fs, 2n), word(fs, 3n), down(word(fs, 4n))}}
    case 2n:
      Some{Move{0, Tool.Mouse{}, float(word(fs, 0n)), float(word(fs, 1n)), word(fs, 2n)}}
    case 3n:
      Some{Key{word(fs, 0n), down(word(fs, 1n))}}
    case 4n:
      Some{Text{text(fs)}}
    case 5n:
      Some{Scroll{float(word(fs, 0n)), float(word(fs, 1n)), float(word(fs, 2n)), float(word(fs, 3n))}}
    case 6n:
      Some{Close{}}
    case 7n:
      Some{Leave{0}}
    case 8n:
      Some{Focus{down(word(fs, 0n))}}
    case k:
      None{}

def event(ws: List<&2, U32>) -> Maybe<&2, Event>:
  match ws:
    case Nil{}:
      None{}
    case Con{k, fs}:
      event.of(U32.to_nat(k), fs)

def events.add(m: Maybe<&2, Event>, rest: List<&2, Event>) -> List<&2, Event>:
  match m:
    case Some{e}:
      Con{e, rest}
    case None{}:
      rest

# The events, from their words.
def events(wss: List<&2, List<&2, U32>>) -> List<&2, Event>:
  match wss:
    case Nil{}:
      Nil{}
    case Con{ws, rest}:
      events.add(event(ws), events(rest))

# Scenes and edits
# ----------------

def bits(v: I.I32) -> U32:
  I.I32.to_u32(v)

# A String's code points, then 0, then rest.
def codes(t: String, rest: List<&2, U32>) -> List<&2, U32>:
  match t:
    case SNil{}:
      0 <> rest
    case SCon{Chr{c}, more}:
      c <> codes(more, rest)

# A scene's words, then rest.
def scene.words(s: S.Scene, rest: List<&2, U32>) -> List<&2, U32>:
  match s:
    case S.Fill{x, y, w, h, c}:
      1 <> bits(x) <> bits(y) <> bits(w) <> bits(h) <> c <> rest
    case S.Label{x, y, z, c, t}:
      2 <> bits(x) <> bits(y) <> z <> c <> codes(t, rest)
    case S.Target{x, y, w, h, t}:
      3 <> rest
    case S.Group{x, y, cs}:
      4 <> bits(x) <> bits(y) <> scene.words(cs, rest)
    case S.End{}:
      5 <> rest
    case S.Child{f, r}:
      6 <> scene.words(f, scene.words(r, rest))

# An edit's words, then rest.
def edit.words(e: S.Edit, rest: List<&2, U32>) -> List<&2, U32>:
  match e:
    case S.Translate{dx, dy}:
      1 <> bits(dx) <> bits(dy) <> rest
    case S.Insert{i, c}:
      2 <> U32.from_nat(i) <> scene.words(c, rest)
    case S.Delete{i}:
      3 <> U32.from_nat(i) <> rest
    case S.Update{i, d}:
      4 <> U32.from_nat(i) <> edit.words(d, rest)
    case S.Shift{i, dx, dy}:
      5 <> U32.from_nat(i) <> bits(dx) <> bits(dy) <> rest

# A run of edits' words.
def edits.words(es: List<&2, S.Edit>) -> List<&2, U32>:
  match es:
    case Nil{}:
      Nil{}
    case Con{e, rest}:
      edit.words(e, edits.words(rest))

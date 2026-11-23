import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../deui/change/change.bend as C
import ../deui/list/list.bend as L
import ../deui/scene/scene.bend as S
import ../deui/column/column.bend as K
import ../deui/app/app.bend as A

# A column of rows. Clicking a row deletes it, and "a" adds a row at the
# top. Each event is a run of edits to the rows, and the column's
# derivative turns it into edits to the scene on screen: the view runs
# once, at launch.

def n(x: U32) -> I.I32:
  I.I32.from_u32(x)

# A row h tall: a fill, and a target over it that a click finds.
def row(+h: U32, color: U32) -> K.Row:
  K.Row{n(h), S.Group{n(0), n(0), S.chain([S.Fill{n(0), n(0), n(200), n(h), color}, S.Target{n(0), n(0), n(200), n(h), 1}])}}

def rows() -> List<&2, K.Row>:
  [row(10, 1), row(20, 2), row(30, 3)]

# A click on a row deletes it: the row's position is the first step of
# the path to its target.
def press(rows: List<&2, K.Row>, h: S.Hit) -> List<&2, L.Edit.of(K.row_edits())>:
  match h:
    case S.Hit{Con{i, rest}, t}:
      [L.Delete{i}]
    case S.Hit{Nil{}, t}:
      Nil{}

# "a" adds a row 5 tall at the top.
def key.a(is_a: Bool) -> List<&2, L.Edit.of(K.row_edits())>:
  match is_a:
    case True{}:
      [L.Insert{0n, row(5, 9)}]
    case False{}:
      Nil{}

def key(rows: List<&2, K.Row>, code: U32) -> List<&2, L.Edit.of(K.row_edits())>:
  key.a(U32.is_eq(code, 97))

# Typing does nothing here.
def text(rows: List<&2, K.Row>, t: String) -> List<&2, L.Edit.of(K.row_edits())>:
  Nil{}

def click(x: F32, y: F32) -> Event:
  Press{0, Tool.Mouse{}, x, y, 0, 0, True{}}

# Click the second row (y 15, in 10 to 30), add a row at the top, then
# click the row now second (y 7, in 5 to 15).
def events() -> List<&2, Event>:
  [click(10.0, 15.0), Key{97, True{}}, click(10.0, 7.0)]

def model() -> A.Model<K.rows_edits()>:
  A.play(~K.rows_edits(), ~K.inc(), ~press, ~key, ~text, events(), A.start(~K.rows_edits(), ~K.inc(), rows()))

# Two scenes are the same, field by field.
def same(a: S.Scene, b: S.Scene) -> Bool:
  match a b:
    case S.Fill{x, y, w, h, c} S.Fill{x2, y2, w2, h2, c2}:
      Bool.and(Bool.and(Bool.and(I.I32.is_eq(x, x2), I.I32.is_eq(y, y2)), Bool.and(I.I32.is_eq(w, w2), I.I32.is_eq(h, h2))), U32.is_eq(c, c2))
    case S.Target{x, y, w, h, t} S.Target{x2, y2, w2, h2, t2}:
      Bool.and(Bool.and(Bool.and(I.I32.is_eq(x, x2), I.I32.is_eq(y, y2)), Bool.and(I.I32.is_eq(w, w2), I.I32.is_eq(h, h2))), U32.is_eq(t, t2))
    case S.Group{x, y, cs} S.Group{x2, y2, cs2}:
      Bool.and(Bool.and(I.I32.is_eq(x, x2), I.I32.is_eq(y, y2)), same(cs, cs2))
    case S.End{} S.End{}:
      True{}
    case S.Child{f, r} S.Child{f2, r2}:
      Bool.and(same(f, f2), same(r, r2))
    case a b:
      False{}

def heights(rows: List<&2, K.Row>) -> String:
  match rows:
    case Nil{}:
      ""
    case Con{K.Row{h, s}, t}:
      String.concat([I.I32.show(h), " ", heights(t)])

def yes(b: Bool) -> String:
  match b:
    case True{}:
      "yes"
    case False{}:
      "no"

# The heights left, and whether the scene on screen is the column drawn
# again from the rows left, as the app's laws say it is.
def report(m: A.Model<K.rows_edits()>) -> String:
  match m:
    case A.Model{+state, scene}:
      String.concat(["heights: ", heights(state), "\nthe scene on screen is the view of the rows: ", yes(same(scene, K.view(state))), "\n"])

def main() -> IO(Unit):
  IO.print(report(model()))

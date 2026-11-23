import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../deui/change/change.bend as C
import ../deui/change/LAWS.bend as CL
import ../deui/change/PROOF.bend as CP
import ../deui/list/list.bend as L
import ../deui/list/LAWS.bend as LL
import ../deui/list/PROOF.bend as LP
import ../deui/scene/scene.bend as S
import ../deui/column/column.bend as K
import ../deui/column/LAWS.bend as KL
import ../deui/column/PROOF.bend as KP
import ../deui/app/app.bend as A
import ./rows.bend as R

# A to-do list. Click an item's box to tick it, and its x to delete it.
# Return starts a new item at the top, typing writes into it, and Backspace
# takes a letter back. Its view is built from proved parts, an item's row
# mapped over the list, then the column, so its derivative is proved
# correct too: the scene on screen stays the view of the items.

type Item is Data:
  Item{text: String, done: Bool}

# An item changes by being replaced; the items change as a list does.
def item_edits() -> C.EditStructure:
  C.whole(~C.none(~Item))

def items_edits() -> C.EditStructure:
  L.edit_structure(~item_edits())

def n(x: U32) -> I.I32:
  I.I32.from_u32(x)

def box_color(done: Bool) -> U32:
  match done:
    case True{}:
      5294180
    case False{}:
      5592405

# An item's row: its box and a target over it (tag 1), its text, and an x
# with a target over it (tag 2).
def row_of(item: Item) -> K.Row:
  match item:
    case Item{t, d}:
      K.Row{n(40), S.Group{n(0), n(0), S.chain([
        S.Fill{n(0), n(0), n(360), n(38), 3158326},
        S.Fill{n(10), n(9), n(20), n(20), box_color(d)},
        S.Target{n(10), n(9), n(20), n(20), 1},
        S.Label{n(42), n(9), 18, 15132390, t},
        S.Label{n(334), n(9), 18, 14706771, "x"},
        S.Target{n(320), n(0), n(40), n(38), 2}])}}

# An item's row, as an incremental function of items that change only by
# being replaced: none of their own edits, so its derivative is never asked.
def row.plain() -> C.Inc<C.none(~Item), C.none(~K.Row)>:
  C.Inc{item => row_of(item), item => e => Empty.absurd(Empty, e)}

def row() -> C.Inc<item_edits(), K.row_edits()>:
  C.whole.lift(~C.none(~Item), ~C.none(~K.Row), ~row.plain())

# The items' rows, then the column of them.
def view() -> C.Inc<C.runs(~items_edits()), C.runs(~S.edit_structure())>:
  C.compose(~C.runs(~items_edits()), ~C.runs(~K.rows_edits()), ~C.runs(~S.edit_structure()),
    ~L.map.inc(~item_edits(), ~K.row_edits(), ~row()), ~K.inc())

# The view's derivative is correct: each part's is, by its law.
def view_ok() -> C.Inc.ok(C.runs(~items_edits()), C.runs(~S.edit_structure()), view()):
  CL.compose_ok(~C.runs(~items_edits()), ~C.runs(~K.rows_edits()), ~C.runs(~S.edit_structure()),
    ~L.map.inc(~item_edits(), ~K.row_edits(), ~row()), ~K.inc(),
    ~LL.map_inc_ok(~item_edits(), ~K.row_edits(), ~row(),
      ~CL.whole_lift_ok(~C.none(~Item), ~C.none(~K.Row), ~row.plain(), ~(item => e => Empty.absurd({C.EditStructure.apply(C.none(~K.Row))(Empty.absurd(Empty, e), row_of(item)) == row_of(C.EditStructure.apply(C.none(~Item))(e, item)) : K.Row}, e)))),
    ~KL.inc_ok())

# Handlers
# --------

def ticked(m: Maybe<&2, Item>, +i: Nat) -> List<&2, L.Edit.of(item_edits())>:
  match m:
    case Some{Item{t, d}}:
      [L.Update{i, C.Replace{Item{t, Bool.not(d)}}}]
    case None{}:
      Nil{}

def pressed.tag(tick: Bool, delete: Bool, +items: List<&2, Item>, +i: Nat) -> List<&2, L.Edit.of(item_edits())>:
  match tick delete:
    case True{} _:
      ticked(List.get(&2, Item, items, i), i)
    case False{} True{}:
      [L.Delete{i}]
    case False{} False{}:
      Nil{}

def pressed.on(+items: List<&2, Item>, +i: Nat, +tag: U32) -> List<&2, L.Edit.of(item_edits())>:
  pressed.tag(U32.is_eq(tag, 1), U32.is_eq(tag, 2), items, i)

# A press on a row's box ticks it, on its x deletes it: the row's position
# is the first step of the path to the target.
def press(+items: List<&2, Item>, h: S.Hit) -> List<&2, L.Edit.of(item_edits())>:
  match h:
    case S.Hit{Con{+i, rest}, +tag}:
      pressed.on(items, i, tag)
    case S.Hit{Nil{}, tag}:
      Nil{}

# The first item, rewritten by f.
def first.with(~f: String -> String, m: Maybe<&2, Item>) -> List<&2, L.Edit.of(item_edits())>:
  match m:
    case Some{Item{t, d}}:
      [L.Update{0n, C.Replace{Item{f(t), d}}}]
    case None{}:
      Nil{}

# A string without its last letter: each letter, kept while another
# follows it.
def shorter.go(t: String, c: Char) -> String:
  match t:
    case SNil{}:
      SNil{}
    case SCon{c2, t2}:
      SCon{c, shorter.go(t2, c2)}

def shorter(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{c, t}:
      shorter.go(t, c)

def key.which(enter: Bool, back: Bool, +items: List<&2, Item>) -> List<&2, L.Edit.of(item_edits())>:
  match enter back:
    case True{} _:
      [L.Insert{0n, Item{"", False{}}}]
    case False{} True{}:
      first.with(~shorter, List.get(&2, Item, items, 0n))
    case False{} False{}:
      Nil{}

# Return starts a new item at the top; Backspace takes a letter from it.
def key(+items: List<&2, Item>, +code: U32) -> List<&2, L.Edit.of(item_edits())>:
  key.which(U32.is_eq(code, 13), U32.is_eq(code, 127), items)

# Appending what was typed to the first item's text.
def typed.into(m: Maybe<&2, Item>, t: String) -> List<&2, L.Edit.of(item_edits())>:
  match m:
    case Some{Item{s, d}}:
      [L.Update{0n, C.Replace{Item{String.append(s, t), d}}}]
    case None{}:
      Nil{}

# Typing writes into the first item.
def text(+items: List<&2, Item>, t: String) -> List<&2, L.Edit.of(item_edits())>:
  typed.into(List.get(&2, Item, items, 0n), t)

def items() -> List<&2, Item>:
  [Item{"Buy milk", False{}}, Item{"Write laws", False{}}]

# Playing it
# ----------

def click(x: F32, y: F32) -> Event:
  Press{0, Tool.Mouse{}, x, y, 0, 0, True{}}

# A new item, typed in; tick the second item's box; delete the third.
def events() -> List<&2, Event>:
  [Key{13, True{}}, Text{"Ship deui"}, click(20.0, 58.0), click(340.0, 100.0)]

# The handlers, as the app takes them.
def handlers.press(items: List<&2, Item>, h: S.Hit) -> List<&2, L.Edit.of(item_edits())>:
  press(items, h)

def handlers.key(items: List<&2, Item>, code: U32) -> List<&2, L.Edit.of(item_edits())>:
  key(items, code)

def handlers.text(items: List<&2, Item>, t: String) -> List<&2, L.Edit.of(item_edits())>:
  text(items, t)

def model() -> A.Model<items_edits()>:
  A.play(~items_edits(), ~view(), ~handlers.press, ~handlers.key, ~handlers.text, events(), A.start(~items_edits(), ~view(), items()))

def shown(items: List<&2, Item>) -> String:
  match items:
    case Nil{}:
      ""
    case Con{Item{t, d}, rest}:
      String.concat([R.yes(d), " ", t, "\n", shown(rest)])

def report(m: A.Model<items_edits()>) -> String:
  match m:
    case A.Model{+state, scene}:
      String.concat(["done? item:\n", shown(state), "the scene on screen is the view of the items: ", R.yes(R.same(scene, C.Inc.f(C.runs(~items_edits()), C.runs(~S.edit_structure()), view())(state))), "\n"])

def main() -> IO(Unit):
  IO.print(report(model()))

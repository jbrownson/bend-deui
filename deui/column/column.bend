import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../list/list.bend as L
import ../scene/scene.bend as S

# A column: rows stacked from the top, each as tall as it says. Its
# derivative turns an edit to the rows into the edits to the column's scene,
# without laying the column out again.

# A row: how tall it is, and what's in it, drawn from the row's top.
type Row is Data:
  Row{h: I.I32, s: S.Scene}

def zero() -> I.I32:
  I.I32{0}

# A row's own edits: rows are replaced whole.
def row_edits() -> C.EditStructure:
  C.whole(~C.none(~Row))

# How the rows are edited: a list's edits, a row replaced whole.
def rows_edits() -> C.EditStructure:
  L.edit_structure(~row_edits())

# A row at y: its scene, in a group placed at the row's top.
def placed(+y: I.I32, s: S.Scene) -> S.Scene:
  S.Group{zero(), y, S.chain([s])}

# The rows placed from y down, each below the one before.
def place(rows: List<&2, Row>, +y: I.I32) -> List<&2, S.Scene>:
  match rows:
    case Nil{}:
      Nil{}
    case Con{Row{+h, s}, t}:
      placed(y, s) <> place(t, (y + h : I.I32))

# The column's scene.
def view(rows: List<&2, Row>) -> S.Scene:
  S.Group{zero(), zero(), S.chain(place(rows, zero()))}

# Where the row at position i starts, the rows placed from y. Past the end,
# where the column ends.
def top(rows: List<&2, Row>, i: Nat, +y: I.I32) -> I.I32:
  match rows i:
    case Nil{} _:
      y
    case Con{r, t} 0n:
      y
    case Con{Row{h, s}, t} 1n+p:
      top(t, p, (y + h : I.I32))

# How tall the row at position i is; past the end, nothing.
def height(rows: List<&2, Row>, i: Nat) -> I.I32:
  match rows i:
    case Nil{} _:
      zero()
    case Con{Row{h, s}, t} 0n:
      h
    case Con{r, t} 1n+p:
      height(t, p)

# The edits inserting a row at i makes: the row, placed where it goes, and
# the rows after it moved down by its height.
def insert.edits(+rows: List<&2, Row>, +i: Nat, r: Row) -> List<&2, S.Edit>:
  match r:
    case Row{+h, s}:
      [S.Insert{i, placed(top(rows, i, zero()), s)}, S.Shift{1n+i, zero(), h}]

# The edits deleting the row at i makes: the row goes, and the rows after it
# move up by its height.
def delete.edits(+rows: List<&2, Row>, +i: Nat) -> List<&2, S.Edit>:
  [S.Delete{i}, S.Shift{i, zero(), (zero() - height(rows, i) : I.I32)}]

# Whether position i holds a row.
def holds(rows: List<&2, Row>, i: Nat) -> Bool:
  match rows i:
    case Nil{} _:
      False{}
    case Con{r, t} 0n:
      True{}
    case Con{r, t} 1n+p:
      holds(t, p)

# Replacing the row at i: deleting it, then inserting the new one, if there
# is a row there; past the end, nothing.
def replace.edits(held: Bool, +rows: List<&2, Row>, +i: Nat, r: Row) -> List<&2, S.Edit>:
  match held:
    case False{}:
      Nil{}
    case True{}:
      List.append(&2, S.Edit, delete.edits(rows, i), insert.edits(L.remove(Row, rows, i), i, r))

# The edits one edit to the rows makes to the column's scene.
def edit(+rows: List<&2, Row>, e: L.Edit.of(row_edits())) -> List<&2, S.Edit>:
  match e:
    case L.Insert{i, r}:
      insert.edits(rows, i, r)
    case L.Delete{i}:
      delete.edits(rows, i)
    case L.Update{+i, w}:
      match w:
        case C.Replace{r}:
          replace.edits(holds(rows, i), rows, i, r)
        case C.Apply{n}:
          Empty.absurd(List<&2, S.Edit>, n)

# The column, for one edit at a time: its view, and its derivative, a run
# of scene edits.
def one() -> C.Inc<rows_edits(), C.runs(~S.edit_structure())>:
  C.Inc{rows => view(rows), rows => e => edit(rows, e)}

# The column, as an incremental function of runs of edits to its rows.
def inc() -> C.Inc<C.runs(~rows_edits()), C.runs(~S.edit_structure())>:
  C.lift(~rows_edits(), ~S.edit_structure(), ~one())

import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../deui/change/change.bend as C
import ../deui/list/list.bend as L
import ../deui/scene/scene.bend as S
import ../deui/column/column.bend as K

def n(x: U32) -> I.I32:
  I.I32.from_u32(x)

# A row of height h, a fill of the given color.
def row(+h: U32, color: U32) -> K.Row:
  K.Row{n(h), S.Fill{n(0), n(0), n(100), n(h), color}}

def rows() -> List<&2, K.Row>:
  [row(10, 1), row(20, 2), row(30, 3)]

# Insert a row of 5 second, delete the first, then replace the last.
def edits() -> List<&2, L.Edit.of(K.row_edits())>:
  [L.Insert{1n, row(5, 9)}, L.Delete{0n}, L.Update{2n, C.Replace{row(7, 8)}}]

# The column's scene patched by the derivative's edits, and drawn again
# from the edited rows: the two are the same.
def main() -> S.Scene & S.Scene:
  (C.run(~S.edit_structure(), C.Inc.df(C.runs(~K.rows_edits()), C.runs(~S.edit_structure()), K.inc())(rows(), edits()), K.view(rows())),
   K.view(L.patch(~K.row_edits(), edits(), rows())))

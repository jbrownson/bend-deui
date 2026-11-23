import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../list/list.bend as L
import ../scene/scene.bend as S
import ./column.bend as K

# What a column promises; PROOF.bend proves it.

# The view
# --------
# A column is a group of its rows, each in a group of its own at the row's
# top, the first at 0 and each below the one before by its height.

# LAW: the column's scene is its rows, placed from 0.
law view:
  for rows: List<&2, K.Row>
  {K.view(rows) == S.Group{K.zero(), K.zero(), S.chain(K.place(rows, K.zero()))} : S.Scene}

# LAW: no rows place nothing.
law place_nil:
  for +y: I.I32
  {K.place(Nil{}, y) == Nil{} : List<&2, S.Scene>}

# LAW: a row is placed at y, and the rows after it below it by its height.
law place_con:
  for +h: I.I32
  for s: S.Scene
  for t: List<&2, K.Row>
  for +y: I.I32
  {K.place(K.Row{h, s} <> t, y) == K.placed(y, s) <> K.place(t, (y + h : I.I32)) : List<&2, S.Scene>}

# The derivative
# --------------
# An edit to the rows becomes edits to the column's scene. top(rows, i, y)
# is where the row at i starts, and height(rows, i) how tall it is.

# LAW: inserting a row at i inserts it, placed where it goes, and moves the
# rows after it down by its height.
law edit_insert:
  for +rows: List<&2, K.Row>
  for +i: Nat
  for +h: I.I32
  for s: S.Scene
  {K.edit(rows, L.Insert{i, K.Row{h, s}}) == [S.Insert{i, K.placed(K.top(rows, i, K.zero()), s)}, S.Shift{1n+i, K.zero(), h}] : List<&2, S.Edit>}

# LAW: deleting the row at i deletes it, and moves the rows after it up by
# its height.
law edit_delete:
  for +rows: List<&2, K.Row>
  for +i: Nat
  {K.edit(rows, L.Delete{i}) == [S.Delete{i}, S.Shift{i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)}] : List<&2, S.Edit>}

# LAW: replacing the row at i deletes it and inserts the new one, as the
# laws above say; past the end, it does nothing.
law edit_replace:
  for +rows: List<&2, K.Row>
  for +i: Nat
  for r: K.Row
  {K.edit(rows, L.Update{i, C.Replace{r}}) == K.replace.edits(K.holds(rows, i), rows, i, r) : List<&2, S.Edit>}

# It follows that:

# LAW: the derivative is correct for every edit: applying its edits to the
# column's scene gives the column of the edited rows.
law one_ok:
  C.Inc.ok(K.rows_edits(), C.runs(~S.edit_structure()), K.one())

# LAW: and for every run of edits.
law inc_ok:
  C.Inc.ok(C.runs(~K.rows_edits()), C.runs(~S.edit_structure()), K.inc())

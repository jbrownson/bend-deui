import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../change/LAWS.bend as CL
import ../change/PROOF.bend as CP
import ../list/list.bend as L
import ../scene/scene.bend as S
import ../scene/LAWS.bend as SL
import ../scene/PROOF.bend as SP
import ../i32/LAWS.bend as IL
import ../i32/PROOF.bend as IP
import ./column.bend as K
import ./LAWS.bend as Laws

# The view and the derivative, as defined
# ---------------------------------------

def Laws.view(rows):
  {==}

def Laws.place_nil(y):
  {==}

def Laws.place_con(h, s, t, y):
  {==}

def Laws.edit_insert(rows, i, h, s):
  {==}

def Laws.edit_delete(rows, i):
  {==}

def Laws.edit_replace(rows, i, r):
  {==}

# Placing, moved
# --------------

# Lemma: adding b then c is adding c then b.
law add_right_comm:
  for +a: I.I32
  for +b: I.I32
  for +c: I.I32
  {((a + b : I.I32) + c : I.I32) == ((a + c : I.I32) + b : I.I32) : I.I32}

def add_right_comm(a, b, c):
  %Equal.sym(I.I32, ((a + c : I.I32) + b : I.I32), (a + (c + b : I.I32) : I.I32), IL.add_assoc(a, c, b)) : {((a + b : I.I32) + c : I.I32) == _ : I.I32}
  %Equal.sym(I.I32, (c + b : I.I32), (b + c : I.I32), IL.add_comm(c, b)) : {((a + b : I.I32) + c : I.I32) == (a + _ : I.I32) : I.I32}
  IL.add_assoc(a, b, c)

# Lemma: placing rows from y, then moving them all down by h, is placing
# them from y + h.
law shift_place:
  for rows: List<&2, K.Row>
  for +y: I.I32
  for +h: I.I32
  {SL.shifted(K.place(rows, y), 0n, K.zero(), h) == K.place(rows, (y + h : I.I32)) : List<&2, S.Scene>}

def shift_place(rows, y, h):
  match rows:
    case Nil{}:
      {==}
    case Con{K.Row{+h0, s0}, t}:
      %Equal.sym(List<&2, S.Scene>, SL.shifted(K.place(t, (y + h0 : I.I32)), 0n, K.zero(), h), K.place(t, ((y + h0 : I.I32) + h : I.I32)), shift_place(t, (y + h0 : I.I32), h)) : {S.apply(K.placed(y, s0), S.Translate{K.zero(), h}) <> _ == K.placed((y + h : I.I32), s0) <> K.place(t, ((y + h : I.I32) + h0 : I.I32)) : List<&2, S.Scene>}
      %add_right_comm(y, h0, h) : {S.apply(K.placed(y, s0), S.Translate{K.zero(), h}) <> K.place(t, ((y + h0 : I.I32) + h : I.I32)) == K.placed((y + h : I.I32), s0) <> K.place(t, _) : List<&2, S.Scene>}
      {==}

# Inserting and deleting
# ----------------------

# Lemma: inserting a row's scene where the row goes and moving the rows
# after it down by its height places the rows with the row inserted.
law insert_core:
  for rows: List<&2, K.Row>
  for i: Nat
  for +y: I.I32
  for +h: I.I32
  for s: S.Scene
  {SL.shifted(L.insert(S.Scene, K.place(rows, y), i, K.placed(K.top(rows, i, y), s)), 1n+i, K.zero(), h) == K.place(L.insert(K.Row, rows, i, K.Row{h, s}), y) : List<&2, S.Scene>}

def insert_core(rows, i, y, h, s):
  match rows i:
    case Nil{} _:
      {==}
    case Con{K.Row{+h0, s0}, t} 0n:
      %Equal.sym(List<&2, S.Scene>, SL.shifted(K.place(K.Row{h0, s0} <> t, y), 0n, K.zero(), h), K.place(K.Row{h0, s0} <> t, (y + h : I.I32)), shift_place(K.Row{h0, s0} <> t, y, h)) : {K.placed(y, s) <> _ == K.placed(y, s) <> K.place(K.Row{h0, s0} <> t, (y + h : I.I32)) : List<&2, S.Scene>}
      {==}
    case Con{K.Row{+h0, s0}, t} 1n+p:
      %insert_core(t, p, (y + h0 : I.I32), h, s) : {K.placed(y, s0) <> SL.shifted(L.insert(S.Scene, K.place(t, (y + h0 : I.I32)), p, K.placed(K.top(t, p, (y + h0 : I.I32)), s)), 1n+p, K.zero(), h) == K.placed(y, s0) <> _ : List<&2, S.Scene>}
      {==}

# Lemma: deleting a row's scene and moving the rows after it up by its
# height places the rows with the row deleted.
law delete_core:
  for rows: List<&2, K.Row>
  for i: Nat
  for +y: I.I32
  {SL.shifted(L.remove(S.Scene, K.place(rows, y), i), i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)) == K.place(L.remove(K.Row, rows, i), y) : List<&2, S.Scene>}

def delete_core(rows, i, y):
  match rows i:
    case Nil{} _:
      {==}
    case Con{K.Row{+h0, s0}, t} 0n:
      %Equal.sym(List<&2, S.Scene>, SL.shifted(K.place(t, (y + h0 : I.I32)), 0n, K.zero(), (K.zero() - h0 : I.I32)), K.place(t, ((y + h0 : I.I32) + (K.zero() - h0 : I.I32) : I.I32)), shift_place(t, (y + h0 : I.I32), (K.zero() - h0 : I.I32))) : {_ == K.place(t, y) : List<&2, S.Scene>}
      %Equal.sym(I.I32, ((y + h0 : I.I32) + (I.I32{0} - h0 : I.I32) : I.I32), y, IL.add_sub_cancel(y, h0)) : {K.place(t, _) == K.place(t, y) : List<&2, S.Scene>}
      {==}
    case Con{K.Row{+h0, s0}, t} 1n+p:
      %delete_core(t, p, (y + h0 : I.I32)) : {K.placed(y, s0) <> SL.shifted(L.remove(S.Scene, K.place(t, (y + h0 : I.I32)), p), p, K.zero(), (K.zero() - K.height(t, p) : I.I32)) == K.placed(y, s0) <> _ : List<&2, S.Scene>}
      {==}

# Lemma: inserting a row's edits give the column with the row inserted.
law insert_ok:
  for +rows: List<&2, K.Row>
  for +i: Nat
  for r: K.Row
  {C.run(~S.edit_structure(), K.insert.edits(rows, i, r), K.view(rows)) == K.view(L.insert(K.Row, rows, i, r)) : S.Scene}

def insert_ok(rows, i, r):
  match r:
    case K.Row{+h, +s}:
      %Equal.sym(S.Scene, S.apply(S.Group{K.zero(), K.zero(), S.chain(K.place(rows, K.zero()))}, S.Insert{i, K.placed(K.top(rows, i, K.zero()), s)}), S.Group{K.zero(), K.zero(), S.chain(L.insert(S.Scene, K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s)))}, SL.group_insert(K.zero(), K.zero(), K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s))) : {S.apply(_, S.Shift{1n+i, K.zero(), h}) == K.view(L.insert(K.Row, rows, i, K.Row{h, s})) : S.Scene}
      %Equal.sym(S.Scene, S.apply(S.Group{K.zero(), K.zero(), S.chain(L.insert(S.Scene, K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s)))}, S.Shift{1n+i, K.zero(), h}), S.Group{K.zero(), K.zero(), S.chain(SL.shifted(L.insert(S.Scene, K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s)), 1n+i, K.zero(), h))}, SL.group_shift(K.zero(), K.zero(), L.insert(S.Scene, K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s)), 1n+i, K.zero(), h)) : {_ == K.view(L.insert(K.Row, rows, i, K.Row{h, s})) : S.Scene}
      %Equal.sym(List<&2, S.Scene>, SL.shifted(L.insert(S.Scene, K.place(rows, K.zero()), i, K.placed(K.top(rows, i, K.zero()), s)), 1n+i, K.zero(), h), K.place(L.insert(K.Row, rows, i, K.Row{h, s}), K.zero()), insert_core(rows, i, K.zero(), h, s)) : {S.Group{K.zero(), K.zero(), S.chain(_)} == K.view(L.insert(K.Row, rows, i, K.Row{h, s})) : S.Scene}
      {==}

# Lemma: deleting a row's edits give the column with the row deleted.
law delete_ok:
  for +rows: List<&2, K.Row>
  for +i: Nat
  {C.run(~S.edit_structure(), K.delete.edits(rows, i), K.view(rows)) == K.view(L.remove(K.Row, rows, i)) : S.Scene}

def delete_ok(rows, i):
  %Equal.sym(S.Scene, S.apply(S.Group{K.zero(), K.zero(), S.chain(K.place(rows, K.zero()))}, S.Delete{i}), S.Group{K.zero(), K.zero(), S.chain(L.remove(S.Scene, K.place(rows, K.zero()), i))}, SL.group_delete(K.zero(), K.zero(), K.place(rows, K.zero()), i)) : {S.apply(_, S.Shift{i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)}) == K.view(L.remove(K.Row, rows, i)) : S.Scene}
  %Equal.sym(S.Scene, S.apply(S.Group{K.zero(), K.zero(), S.chain(L.remove(S.Scene, K.place(rows, K.zero()), i))}, S.Shift{i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)}), S.Group{K.zero(), K.zero(), S.chain(SL.shifted(L.remove(S.Scene, K.place(rows, K.zero()), i), i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)))}, SL.group_shift(K.zero(), K.zero(), L.remove(S.Scene, K.place(rows, K.zero()), i), i, K.zero(), (K.zero() - K.height(rows, i) : I.I32))) : {_ == K.view(L.remove(K.Row, rows, i)) : S.Scene}
  %Equal.sym(List<&2, S.Scene>, SL.shifted(L.remove(S.Scene, K.place(rows, K.zero()), i), i, K.zero(), (K.zero() - K.height(rows, i) : I.I32)), K.place(L.remove(K.Row, rows, i), K.zero()), delete_core(rows, i, K.zero())) : {S.Group{K.zero(), K.zero(), S.chain(_)} == K.view(L.remove(K.Row, rows, i)) : S.Scene}
  {==}

# Replacing
# ---------

def IsTrue(b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      Empty

# Helper: true isn't false.
law true_false:
  for e: {True{} == False{} : Bool}
  Empty

def true_false(e):
  %e : IsTrue(_)
  Unit{}

# Helper: false isn't true.
law false_true:
  for e: {False{} == True{} : Bool}
  Empty

def false_true(e):
  true_false(Equal.sym(Bool, False{}, True{}, e))

# Lemma: past the end, replacing a row leaves the rows as they are.
law update_absent:
  for rows: List<&2, K.Row>
  for i: Nat
  for r: K.Row
  for e: {K.holds(rows, i) == False{} : Bool}
  {L.update(~K.row_edits(), rows, i, C.Replace{r}) == rows : List<&2, K.Row>}

def update_absent(rows, i, r, e):
  match rows i:
    case Nil{} _:
      {==}
    case Con{x, t} 0n:
      Empty.absurd({L.update(~K.row_edits(), x <> t, 0n, C.Replace{r}) == x <> t : List<&2, K.Row>}, true_false(e))
    case Con{x, t} 1n+p:
      %update_absent(t, p, r, e) : {x <> L.update(~K.row_edits(), t, p, C.Replace{r}) == x <> _ : List<&2, K.Row>}
      {==}

# Lemma: where there's a row, replacing it is deleting it and inserting
# the new one.
law update_present:
  for rows: List<&2, K.Row>
  for i: Nat
  for r: K.Row
  for e: {K.holds(rows, i) == True{} : Bool}
  {L.update(~K.row_edits(), rows, i, C.Replace{r}) == L.insert(K.Row, L.remove(K.Row, rows, i), i, r) : List<&2, K.Row>}

def update_present(rows, i, r, e):
  match rows i:
    case Nil{} _:
      Empty.absurd({L.update(~K.row_edits(), Nil{}, i, C.Replace{r}) == L.insert(K.Row, L.remove(K.Row, Nil{}, i), i, r) : List<&2, K.Row>}, false_true(e))
    case Con{x, +t} 0n:
      %Equal.sym(List<&2, K.Row>, L.insert(K.Row, t, 0n, r), r <> t, L.insert.front(K.Row, t, r)) : {r <> t == _ : List<&2, K.Row>}
      {==}
    case Con{x, t} 1n+p:
      %update_present(t, p, r, e) : {x <> L.update(~K.row_edits(), t, p, C.Replace{r}) == x <> _ : List<&2, K.Row>}
      {==}

# Lemma: replacing a row's edits give the column with the row replaced.
law replace_ok:
  for held: Bool
  for +rows: List<&2, K.Row>
  for +i: Nat
  for +r: K.Row
  for e: {K.holds(rows, i) == held : Bool}
  {C.run(~S.edit_structure(), K.replace.edits(held, rows, i, r), K.view(rows)) == K.view(L.update(~K.row_edits(), rows, i, C.Replace{r})) : S.Scene}

def replace_ok(held, rows, i, r, e):
  match held:
    case False{}:
      %Equal.sym(List<&2, K.Row>, L.update(~K.row_edits(), rows, i, C.Replace{r}), rows, update_absent(rows, i, r, e)) : {K.view(rows) == K.view(_) : S.Scene}
      {==}
    case True{}:
      %Equal.sym(S.Scene, C.run(~S.edit_structure(), List.append(&2, S.Edit, K.delete.edits(rows, i), K.insert.edits(L.remove(K.Row, rows, i), i, r)), K.view(rows)), C.run(~S.edit_structure(), K.insert.edits(L.remove(K.Row, rows, i), i, r), C.run(~S.edit_structure(), K.delete.edits(rows, i), K.view(rows))), CL.run_append(~S.edit_structure(), K.delete.edits(rows, i), K.insert.edits(L.remove(K.Row, rows, i), i, r), K.view(rows))) : {_ == K.view(L.update(~K.row_edits(), rows, i, C.Replace{r})) : S.Scene}
      %Equal.sym(S.Scene, C.run(~S.edit_structure(), K.delete.edits(rows, i), K.view(rows)), K.view(L.remove(K.Row, rows, i)), delete_ok(rows, i)) : {C.run(~S.edit_structure(), K.insert.edits(L.remove(K.Row, rows, i), i, r), _) == K.view(L.update(~K.row_edits(), rows, i, C.Replace{r})) : S.Scene}
      %Equal.sym(S.Scene, C.run(~S.edit_structure(), K.insert.edits(L.remove(K.Row, rows, i), i, r), K.view(L.remove(K.Row, rows, i))), K.view(L.insert(K.Row, L.remove(K.Row, rows, i), i, r)), insert_ok(L.remove(K.Row, rows, i), i, r)) : {_ == K.view(L.update(~K.row_edits(), rows, i, C.Replace{r})) : S.Scene}
      %Equal.sym(List<&2, K.Row>, L.update(~K.row_edits(), rows, i, C.Replace{r}), L.insert(K.Row, L.remove(K.Row, rows, i), i, r), update_present(rows, i, r, e)) : {K.view(L.insert(K.Row, L.remove(K.Row, rows, i), i, r)) == K.view(_) : S.Scene}
      {==}

# The column
# ----------

# Lemma: one edit's edits give the column of the edited rows.
law edit_ok:
  for +rows: List<&2, K.Row>
  for e: L.Edit.of(K.row_edits())
  {C.run(~S.edit_structure(), K.edit(rows, e), K.view(rows)) == K.view(L.edit(~K.row_edits(), e, rows)) : S.Scene}

def edit_ok(rows, e):
  match e:
    case L.Insert{i, r}:
      insert_ok(rows, i, r)
    case L.Delete{i}:
      delete_ok(rows, i)
    case L.Update{+i, w}:
      match w:
        case C.Replace{r}:
          replace_ok(K.holds(rows, i), rows, i, r, {==})
        case C.Apply{n}:
          Empty.absurd({C.run(~S.edit_structure(), K.edit(rows, L.Update{i, C.Apply{n}}), K.view(rows)) == K.view(L.edit(~K.row_edits(), L.Update{i, C.Apply{n}}, rows)) : S.Scene}, n)

def Laws.one_ok():
  rows => e => edit_ok(rows, e)

def Laws.inc_ok():
  CL.lift_ok(~K.rows_edits(), ~S.edit_structure(), ~K.one(), ~(rows => e => edit_ok(rows, e)))

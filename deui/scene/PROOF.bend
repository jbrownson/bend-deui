import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../list/list.bend as L
import ./scene.bend as S
import ./LAWS.bend as Laws

# Children
# --------
# Each children edit, applied to a chain, by induction on the list it was
# made from.

# Lemma: inserting into a chain inserts into its list.
law chain_insert:
  for xs: List<&2, S.Scene>
  for i: Nat
  for c: S.Scene
  {S.apply(S.chain(xs), S.Insert{i, c}) == S.chain(L.insert(S.Scene, xs, i, c)) : S.Scene}

def chain_insert(xs, i, c):
  match xs i:
    case Nil{} _:
      {==}
    case Con{h, t} 0n:
      {==}
    case Con{h, t} 1n+p:
      %chain_insert(t, p, c) : {S.Child{h, S.apply(S.chain(t), S.Insert{p, c})} == S.Child{h, _} : S.Scene}
      {==}

# Lemma: deleting from a chain deletes from its list.
law chain_delete:
  for xs: List<&2, S.Scene>
  for i: Nat
  {S.apply(S.chain(xs), S.Delete{i}) == S.chain(L.remove(S.Scene, xs, i)) : S.Scene}

def chain_delete(xs, i):
  match xs i:
    case Nil{} _:
      {==}
    case Con{h, t} 0n:
      {==}
    case Con{h, t} 1n+p:
      %chain_delete(t, p) : {S.Child{h, S.apply(S.chain(t), S.Delete{p})} == S.Child{h, _} : S.Scene}
      {==}

# Lemma: updating a chain updates its list.
law chain_update:
  for xs: List<&2, S.Scene>
  for i: Nat
  for d: S.Edit
  {S.apply(S.chain(xs), S.Update{i, d}) == S.chain(L.update(~S.edit_structure(), xs, i, d)) : S.Scene}

def chain_update(xs, i, d):
  match xs i:
    case Nil{} _:
      {==}
    case Con{h, t} 0n:
      {==}
    case Con{h, t} 1n+p:
      %chain_update(t, p, d) : {S.Child{h, S.apply(S.chain(t), S.Update{p, d})} == S.Child{h, _} : S.Scene}
      {==}

# Lemma: shifting a chain shifts its list.
law chain_shift:
  for xs: List<&2, S.Scene>
  for i: Nat
  for +dx: I.I32
  for +dy: I.I32
  {S.apply(S.chain(xs), S.Shift{i, dx, dy}) == S.chain(Laws.shifted(xs, i, dx, dy)) : S.Scene}

def chain_shift(xs, i, dx, dy):
  match xs i:
    case Nil{} _:
      {==}
    case Con{h, t} 0n:
      %chain_shift(t, 0n, dx, dy) : {S.Child{S.apply(h, S.Translate{dx, dy}), S.apply(S.chain(t), S.Shift{0n, dx, dy})} == S.Child{S.apply(h, S.Translate{dx, dy}), _} : S.Scene}
      {==}
    case Con{h, t} 1n+p:
      %chain_shift(t, p, dx, dy) : {S.Child{h, S.apply(S.chain(t), S.Shift{p, dx, dy})} == S.Child{h, _} : S.Scene}
      {==}

# Moving
# ------

def Laws.translate_fill(x, y, w, h, c, dx, dy):
  {==}

def Laws.translate_label(x, y, z, c, t, dx, dy):
  {==}

def Laws.translate_target(x, y, w, h, t, dx, dy):
  {==}

def Laws.translate_group(x, y, cs, dx, dy):
  {==}

# A group's children
# ------------------

def Laws.group_insert(x, y, xs, i, c):
  %chain_insert(xs, i, c) : {S.Group{x, y, S.apply(S.chain(xs), S.Insert{i, c})} == S.Group{x, y, _} : S.Scene}
  {==}

def Laws.group_delete(x, y, xs, i):
  %chain_delete(xs, i) : {S.Group{x, y, S.apply(S.chain(xs), S.Delete{i})} == S.Group{x, y, _} : S.Scene}
  {==}

def Laws.group_update(x, y, xs, i, d):
  %chain_update(xs, i, d) : {S.Group{x, y, S.apply(S.chain(xs), S.Update{i, d})} == S.Group{x, y, _} : S.Scene}
  {==}

def Laws.group_shift(x, y, xs, i, dx, dy):
  %chain_shift(xs, i, dx, dy) : {S.Group{x, y, S.apply(S.chain(xs), S.Shift{i, dx, dy})} == S.Group{x, y, _} : S.Scene}
  {==}

# Edits
# -----

def Laws.edit_structure():
  {==}

# Hitting
# -------

def Laws.hit_fill(x, y, w, h, c, i, px, py):
  {==}

def Laws.hit_label(x, y, z, c, t, i, px, py):
  {==}

def Laws.hit_target(x, y, w, h, t, i, px, py):
  {==}

def Laws.hit_group(x, y, cs, i, px, py):
  {==}

def Laws.hit_child(f, r, i, px, py):
  {==}

def Laws.hit_end(i, px, py):
  {==}

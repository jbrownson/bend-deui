import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../list/list.bend as L
import ./scene.bend as S

# What a scene's edits promise; PROOF.bend proves it.

# shifted(xs, i, dx, dy): xs, with each element from position i on
# translated by dx and dy.
def shifted(xs: List<&2, S.Scene>, i: Nat, +dx: I.I32, +dy: I.I32) -> List<&2, S.Scene>:
  match xs i:
    case Nil{} _:
      Nil{}
    case Con{h, t} 0n:
      S.apply(h, S.Translate{dx, dy}) <> shifted(t, 0n, dx, dy)
    case Con{h, t} 1n+p:
      h <> shifted(t, p, dx, dy)

# Moving
# ------
# A fill or a group sits at an offset from the group it's in.

# LAW: translating a fill moves it.
law translate_fill:
  for x: I.I32
  for y: I.I32
  for w: I.I32
  for h: I.I32
  for c: U32
  for dx: I.I32
  for dy: I.I32
  {S.apply(S.Fill{x, y, w, h, c}, S.Translate{dx, dy}) == S.Fill{(x + dx : I.I32), (y + dy : I.I32), w, h, c} : S.Scene}

# LAW: translating a group moves it, and what's in it with it: its
# children's offsets are from the group, so they stay as they are.
law translate_group:
  for x: I.I32
  for y: I.I32
  for cs: S.Scene
  for dx: I.I32
  for dy: I.I32
  {S.apply(S.Group{x, y, cs}, S.Translate{dx, dy}) == S.Group{(x + dx : I.I32), (y + dy : I.I32), cs} : S.Scene}

# A group's children
# ------------------
# Insert, Delete, Update and Shift edit a group's children, which
# S.chain makes from a list. They edit them as a list's edits would:
# L.insert, L.remove and L.update, and shifted.

# LAW: inserting into a group inserts into its children.
law group_insert:
  for x: I.I32
  for y: I.I32
  for xs: List<&2, S.Scene>
  for i: Nat
  for c: S.Scene
  {S.apply(S.Group{x, y, S.chain(xs)}, S.Insert{i, c}) == S.Group{x, y, S.chain(L.insert(S.Scene, xs, i, c))} : S.Scene}

# LAW: deleting from a group deletes from its children.
law group_delete:
  for x: I.I32
  for y: I.I32
  for xs: List<&2, S.Scene>
  for i: Nat
  {S.apply(S.Group{x, y, S.chain(xs)}, S.Delete{i}) == S.Group{x, y, S.chain(L.remove(S.Scene, xs, i))} : S.Scene}

# LAW: updating a group's child applies the edit to that child.
law group_update:
  for x: I.I32
  for y: I.I32
  for xs: List<&2, S.Scene>
  for i: Nat
  for d: S.Edit
  {S.apply(S.Group{x, y, S.chain(xs)}, S.Update{i, d}) == S.Group{x, y, S.chain(L.update(~S.edit_structure(), xs, i, d))} : S.Scene}

# LAW: shifting a group's children from i translates each of them from i
# on.
law group_shift:
  for x: I.I32
  for y: I.I32
  for xs: List<&2, S.Scene>
  for i: Nat
  for dx: I.I32
  for dy: I.I32
  {S.apply(S.Group{x, y, S.chain(xs)}, S.Shift{i, dx, dy}) == S.Group{x, y, S.chain(shifted(xs, i, dx, dy))} : S.Scene}

# Edits
# -----

# LAW: a scene changes by one edit as S.apply says.
law edit_structure:
  {S.edit_structure() == C.EditStructure{S.Scene, S.Edit, e => s => S.apply(s, e)} : C.EditStructure}

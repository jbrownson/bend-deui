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
# A fill, a label, a target or a group sits at an offset from the group
# it's in.

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

# LAW: translating a label moves it.
law translate_label:
  for x: I.I32
  for y: I.I32
  for z: U32
  for c: U32
  for t: String
  for dx: I.I32
  for dy: I.I32
  {S.apply(S.Label{x, y, z, c, t}, S.Translate{dx, dy}) == S.Label{(x + dx : I.I32), (y + dy : I.I32), z, c, t} : S.Scene}

# LAW: translating a target moves it.
law translate_target:
  for x: I.I32
  for y: I.I32
  for w: I.I32
  for h: I.I32
  for t: U32
  for dx: I.I32
  for dy: I.I32
  {S.apply(S.Target{x, y, w, h, t}, S.Translate{dx, dy}) == S.Target{(x + dx : I.I32), (y + dy : I.I32), w, h, t} : S.Scene}

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

# Hitting
# -------
# hit(s, i, px, py) is what the point (px, py) lands on in s: the topmost
# target containing it, as the path to it through each group's children
# by position, and its tag. i is the position of a chain's first child.

# LAW: a fill is never hit.
law hit_fill:
  for x: I.I32
  for y: I.I32
  for w: I.I32
  for h: I.I32
  for c: U32
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.Fill{x, y, w, h, c}, i, px, py) == None{} : Maybe<&2, S.Hit>}

# LAW: a label is never hit: a target over it is what a pointer finds.
law hit_label:
  for x: I.I32
  for y: I.I32
  for z: U32
  for c: U32
  for t: String
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.Label{x, y, z, c, t}, i, px, py) == None{} : Maybe<&2, S.Hit>}

# LAW: a target is hit where the point is inside it, from its left and top
# edges up to but not including its right and bottom ones.
law hit_target:
  for x: I.I32
  for y: I.I32
  for w: I.I32
  for h: I.I32
  for t: U32
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.Target{x, y, w, h, t}, i, px, py) == S.hit.target(Bool.and(S.within(x, w, px), S.within(y, h, py)), t) : Maybe<&2, S.Hit>}

# LAW: inside a group, the point is in its children's coordinates, moved by
# the group's offset.
law hit_group:
  for x: I.I32
  for y: I.I32
  for cs: S.Scene
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.Group{x, y, cs}, i, px, py) == S.hit(cs, 0n, (px - x : I.I32), (py - y : I.I32)) : Maybe<&2, S.Hit>}

# LAW: a group's later children are on top, so they're asked first, and a
# hit inside a child has the child's position on its path.
law hit_child:
  for f: S.Scene
  for r: S.Scene
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.Child{f, r}, i, px, py) == S.hit.later(S.hit(r, 1n+i, px, py), S.hit.under(i, S.hit(f, 0n, px, py))) : Maybe<&2, S.Hit>}

# LAW: a group with no children is never hit.
law hit_end:
  for +i: Nat
  for +px: I.I32
  for +py: I.I32
  {S.hit(S.End{}, i, px, py) == None{} : Maybe<&2, S.Hit>}

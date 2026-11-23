import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C

# What's on the screen: a tree of fills and groups, each placed at an
# offset from the group it's in, so moving anything, however much is in it,
# is one edit. A group's children are a chain of the same type, End or
# Child{first, rest}, so one function walks scenes and their children
# alike: Bend has no mutual recursion.
type Scene is Data:
  Fill{x: I.I32, y: I.I32, w: I.I32, h: I.I32, color: U32}
  Group{x: I.I32, y: I.I32, children: Scene}
  End{}
  Child{first: Scene, rest: Scene}

# A scene's own edits. Translate moves a fill or a group. Insert, Delete,
# Update and Shift act on a group's children by position, counting from 0:
# Update applies an edit to the child at a position, and Shift translates
# every child from a position on, so a column takes a change in one edit
# rather than one for each child below it. An edit that doesn't fit what
# it meets leaves it as it is.
type Edit is Data:
  Translate{dx: I.I32, dy: I.I32}
  Insert{at: Nat, child: Scene}
  Delete{at: Nat}
  Update{at: Nat, edit: Edit}
  Shift{from: Nat, dx: I.I32, dy: I.I32}

# The scene after one edit. The scene comes first, so each recursive call
# is on a smaller part of it.
def apply(s: Scene, e: Edit) -> Scene:
  match s e:
    case Fill{x, y, w, h, c} Translate{dx, dy}:
      Fill{(x + dx : I.I32), (y + dy : I.I32), w, h, c}
    case Group{x, y, cs} Translate{dx, dy}:
      Group{(x + dx : I.I32), (y + dy : I.I32), cs}
    case Group{x, y, cs} Insert{i, c}:
      Group{x, y, apply(cs, Insert{i, c})}
    case Group{x, y, cs} Delete{i}:
      Group{x, y, apply(cs, Delete{i})}
    case Group{x, y, cs} Update{i, d}:
      Group{x, y, apply(cs, Update{i, d})}
    case Group{x, y, cs} Shift{i, dx, dy}:
      Group{x, y, apply(cs, Shift{i, dx, dy})}
    case End{} Insert{i, c}:
      Child{c, End{}}
    case Child{f, r} Insert{0n, c}:
      Child{c, Child{f, r}}
    case Child{f, r} Insert{1n+p, c}:
      Child{f, apply(r, Insert{p, c})}
    case Child{f, r} Delete{0n}:
      r
    case Child{f, r} Delete{1n+p}:
      Child{f, apply(r, Delete{p})}
    case Child{f, r} Update{0n, d}:
      Child{apply(f, d), r}
    case Child{f, r} Update{1n+p, d}:
      Child{f, apply(r, Update{p, d})}
    case Child{f, r} Shift{0n, +dx, +dy}:
      Child{apply(f, Translate{dx, dy}), apply(r, Shift{0n, dx, dy})}
    case Child{f, r} Shift{1n+p, dx, dy}:
      Child{f, apply(r, Shift{p, dx, dy})}
    case s e:
      s

# A group's children, from a list of them.
def chain(xs: List<&2, Scene>) -> Scene:
  match xs:
    case Nil{}:
      End{}
    case Con{h, t}:
      Child{h, chain(t)}

# A scene's edit structure: one edit at a time. C.runs makes runs of
# them, and C.whole adds replacing the scene, which reaches any scene.
def edit_structure() -> C.EditStructure:
  C.EditStructure{Scene, Edit, e => s => apply(s, e)}

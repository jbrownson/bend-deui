# deui for Bend

deui, said "dewey": dUI, the change in the UI. A view is a pure function of
one state, as [Puri](https://github.com/jbrownson/bend-puri) makes it, and
deui gives it a derivative: from the state and a change to it, the change to
the screen. A law says the derivative is right, that applying its change
gives what drawing again would, and Bend's prover checks it. The work a
frame does is then the size of the change, not the size of the view.
[Two Piles of State](https://jbrownson.github.io/two-piles/) explains why.

## Files

A module with laws has a directory of its own: the module, `LAWS.bend`,
what it promises, and `PROOF.bend`, their proofs. The laws say what each
operation returns, case by case, so reading them is enough to know what it
does. Laws under "It follows that" add nothing new: they are consequences,
checked so you don't have to work them out. `PROOF.bend` at the root checks
every module's proofs.

`deui/`, the library:

- `i32/`: what coordinates' addition promises: in either order, and in
  either grouping, it gives the same. Proved through Nat with
  bend-mathlib's lemmas about U32.
- `change/`: edits to any value. An edit structure (`EditStructure`) says
  how a type's values are edited: the type of the values (`Value`), the type
  of their edits (`Edit`), and how to apply one. A change structure
  (`ChangeStructure`) is an edit structure with the proof that one edit gets
  from any value to any other (`reaches`). Two layers build on any edit
  structure: `runs`, whose edits are runs of its edits applied in order, and
  `whole`, whose edits are its edits or a replacement with a whole new
  value, which makes a change structure of anything. An `Inc<ca, cb>` pairs
  a function, from values edited as `ca` says to values edited as `cb` says,
  with its derivative, which gives the edit to the function's result from an
  edit to its input. `lift` turns an `Inc` whose derivative gives a run for
  one edit into one that handles runs, and `whole.lift` lifts one to values
  that can also be replaced. The laws say what each operation returns, and
  that lifting a correct `Inc` gives a correct one.
- `list/`: a list's edits (insert, delete, and update an element in place),
  given how its elements are edited (`edit_structure`), `patch` to apply a
  run of them, `diff`, a run from any list to any other, and `map.inc`,
  which maps an `Inc` over lists; its derivative is `dmap`. A list's change
  structure (`change_structure`) is runs of its edits. The laws cover edits
  whose positions are in range (`valid`), and say what each edit does, that
  `diff` gets there, what `dmap` returns for each edit, that `map.inc(g)` is
  correct when `g` is, that `dmap` acts exactly where the edits act, and
  that it turns valid edits into valid ones.
- `scene/`: what's on the screen. A scene is a tree of fills and groups,
  each at an offset from the group it's in, so moving anything is one
  edit (`Translate`). A group's children are edited by position, as a list
  is (`Insert`, `Delete`, `Update`), and `Shift` translates every child
  from a position on, so a column takes a change in one edit rather than
  one for each child below it. A group's children are a chain of the same
  type, built from a list by `chain`, because Bend has no mutual recursion.
  The laws say what each edit does, and that a group's children change
  exactly as the list they're made from would. Coordinates are
  bend-kit-int's `I32`.
- `column/`: the first view with a derivative. A column stacks rows, each
  as tall as it says, from the top. Its derivative turns an edit to the
  rows into a few edits to its scene, whatever its size: inserting a row
  inserts it where it goes and shifts the rows below down by its height,
  deleting one deletes it and shifts them back up, and replacing one is
  both. The laws say what those edits are, and that applying them gives
  the column of the edited rows, for every edit and every run of them.

`examples/`:

- `lists.bend`: `dmap` on concrete lists of numbers: the edits that mapping
  makes, checked against mapping from scratch, a map over lists of lists,
  and `diff`'s run between two lists.
- `scene.bend`: a column of rows; a row inserted second, then one `Shift`
  moves the rows below it.
- `column.bend`: a column patched by its derivative's edits, beside the
  column drawn again from the edited rows: the two are the same.

`change/` and `list/` began in bend-puri, as its `ilc/`, at `7b711ea`; their
history is there.

The approach follows Phil Freeman's
[Purview](https://github.com/paf31/purescript-purview), a PureScript UI
library built on incremental computation, and his
[purescript-incremental-functions](https://github.com/paf31/purescript-incremental-functions),
from the theory in Cai, Giarrusso, Rendel and Ostermann, ["A Theory of
Changes for Higher-Order Languages"](https://arxiv.org/abs/1312.0658).

## Dependencies

From [BendHub](https://hub.bend-lang.com/packages), imported by content
hash, so `bend` fetches exactly that code on first use and checks it:

- `bend-kit-int` (`0x4eed9d7a…`), the `I32` used for coordinates.
- `bend-mathlib` 0.8.1.1 (`0x15432fae…`), lemmas about Nat and U32.

## Running

```sh
bend PROOF.bend               # ALL PROOFS CHECK when every law holds
bend deui/list/PROOF.bend     # or one module's laws
bend examples/lists.bend      # computes a mapped list's edits
bend examples/scene.bend      # edits a column of rows
bend examples/column.bend     # patches a column, and draws it again
```

`bend <file> --verdict` checks a proof a second time with Bend's BendTT
kernel, which has its own proof in Lean, and confirms nothing relies on
`@unsafe` or foreign code. It needs Lean 4.34.0 (the elan toolchain
`leanprover/lean4:v4.34.0`) to build the kernel on first use.

Tested with Bend 2.0.40.

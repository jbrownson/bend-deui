# Working here

Read `README.md` first for what the repository is.

## How work is read and decided

- **The laws are the reading surface.** `LAWS.bend` files are what gets
  read, not the code. Laws exist for what a reader needs plus anything
  tricky. Record field accessors and small helper steps don't get laws.
  Definitions that restate a structure (`runs`, `whole`, `lift`, ...) do,
  even when their proof is `{==}`, because that's where a reader learns
  what they are.
- **Questions are questions.** A question asked to understand something is
  not a request to change it. When something should change, say so and
  why; for changes to what's read (laws, names, structure), wait for a
  yes. For small, clearly good fixes, decide, do it, and report.
- **Honest assessments.** Don't agree to be agreeable, and don't dress a
  weakness up as a strength. Speed matters in absolute terms, not relative
  ones.
- **Names:** prefer descriptive structure to terse names, and don't
  replace spelled-out terms with new abbreviations without asking.
- **Comments don't document Bend itself.**

## Changes

- Commit to `main` and push; no pull requests unless asked.
- `bend PROOF.bend` and `bend PROOF.bend --verdict` must both pass, and
  the examples must run.
- For a new law, run a sabotage check: break the code or the law and
  confirm the checker rejects it.

## Bend notes

- Restrictions the checker enforces:
  - Define before use.
  - No mutual recursion.
  - `match` and destructuring only on parameters or fields, so give a
    computed value its own def.
  - Operators need a type: `(a + b : U32)`.
  - `+x` to use a value more than once.
  - There's no `?:`.
- `--verdict` can't model a proof passed as a `~` template parameter. Take
  it as an ordinary parameter.
- Template (`~`) arguments must be closed, so a function passed as one
  can't capture runtime values.
- A compound type argument takes parentheses: `Loop.Step<(M & R)>`. A `+`
  binding needs its type to be `Data`, so a generic model is `~M: Data`.

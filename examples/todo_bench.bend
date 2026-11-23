import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../deui/change/change.bend as C
import ../deui/list/list.bend as L
import ../deui/scene/scene.bend as S
import ../deui/app/app.bend as A
import ./todo.bend as T

# How long the to-do list takes with many items: typing into the first
# item through the view's derivative, as the app does, or by running the
# view again after each key, and starting new items at the top, which
# moves every row below. Run natively under `time`, with main changed to
# the mode and sizes to measure; each prints how many rows it ended with.

def many(k: Nat) -> List<&2, T.Item>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      T.Item{"an item", False{}} <> many(p)

def keys(k: Nat) -> List<&2, Event>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      Text{"a"} <> keys(p)

def enters(k: Nat) -> List<&2, Event>:
  match k:
    case 0n:
      Nil{}
    case 1n+p:
      Key{13, True{}} <> enters(p)

# How many children a scene's top group has, to make sure it was built.
def count(s: S.Scene, acc: U32) -> U32:
  match s:
    case S.Group{x, y, cs}:
      count(cs, acc)
    case S.Child{f, r}:
      count(r, (acc + 1 : U32))
    case s:
      acc

# The incremental path: the app's own.
def incremental(+items: Nat, +events: Nat) -> U32:
  count(A.scene(T.items_edits(), T.view(), A.play(~T.items_edits(), ~T.view(), ~T.handlers.press, ~T.handlers.key, ~T.handlers.text, keys(events),
    A.start(~T.items_edits(), ~T.view(), many(items)))), 0)

# Return, again and again: a new item at the top each time, which moves
# every row below it.
def entering(+items: Nat, +events: Nat) -> U32:
  count(A.scene(T.items_edits(), T.view(), A.play(~T.items_edits(), ~T.view(), ~T.handlers.press, ~T.handlers.key, ~T.handlers.text, enters(events),
    A.start(~T.items_edits(), ~T.view(), many(items)))), 0)

# Running the view again after each event, counting what it built.
def again(es: List<&2, Event>, +state: List<&2, T.Item>, acc: U32) -> U32:
  match es:
    case Nil{}:
      acc
    case Con{Text{t}, rest}:
      +next = C.run(~T.items_edits(), T.handlers.text(state, t), state)
      again(rest, next, (acc + count(C.Kept.result(S.Scene, A.Cache(T.items_edits(), T.view()), C.Cached.f(C.runs(~T.items_edits()), C.runs(~S.edit_structure()), T.view())(next)), 0) : U32))
    case Con{e, rest}:
      again(rest, state, acc)

def recompute(+items: Nat, +events: Nat) -> U32:
  again(keys(events), many(items), 0)

def main() -> IO(Unit):
  IO.print(String.concat(["incremental: ", U32.show(incremental(8000n, 400n)), "\n"]))

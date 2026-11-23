import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ./app.bend as A

# What an app promises; PROOF.bend proves it.

# shows(m): what's shown is what the view gives for the state, the scene
# on screen and what the view keeps, as if the view had run again.
def shows(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>, m: A.Model<cs, view>) -> Type:
  match m:
    case A.Model{state, shown}:
      {shown == C.Cached.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state) : C.Kept<S.Scene, A.Cache(cs, view)>}

# LAW: at launch, the scene on screen is the view of the state.
law start_shows:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for +state: C.Value(cs)
  shows(~cs, ~view, A.start(~cs, ~view, state))

# LAW: if the view's derivative is correct, an event keeps the scene on
# screen the view of the state, without running the view again.
law step_shows:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for view_ok: C.Cached.ok(C.runs(~cs), C.runs(~S.edit_structure()), view)
  for m: A.Model<cs, view>
  for e: Event
  for h: shows(~cs, ~view, m)
  shows(~cs, ~view, A.step(~cs, ~view, ~press, ~key, ~text, m, e))

# It follows that:

# LAW: and so does any run of events.
law play_shows:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for ~view_ok: C.Cached.ok(C.runs(~cs), C.runs(~S.edit_structure()), view)
  for events: List<&2, Event>
  for +m: A.Model<cs, view>
  for h: shows(~cs, ~view, m)
  shows(~cs, ~view, A.play(~cs, ~view, ~press, ~key, ~text, events, m))

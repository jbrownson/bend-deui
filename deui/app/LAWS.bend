import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ./app.bend as A

# What an app promises; PROOF.bend proves it.

# shows(m): the scene on screen is the view of the state, as if the view
# had run again.
def shows(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>, m: A.Model<cs>) -> Type:
  match m:
    case A.Model{state, scene}:
      {scene == C.Inc.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state) : S.Scene}

# LAW: at launch, the scene on screen is the view of the state.
law start_shows:
  for ~cs: C.EditStructure
  for ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>
  for +state: C.Value(cs)
  shows(~cs, ~view, A.start(~cs, ~view, state))

# LAW: if the view's derivative is correct, an event keeps the scene on
# screen the view of the state, without running the view again.
law step_shows:
  for ~cs: C.EditStructure
  for ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for view_ok: C.Inc.ok(C.runs(~cs), C.runs(~S.edit_structure()), view)
  for m: A.Model<cs>
  for e: Event
  for h: shows(~cs, ~view, m)
  shows(~cs, ~view, A.step(~cs, ~view, ~press, ~key, m, e))

# It follows that:

# LAW: and so does any run of events.
law play_shows:
  for ~cs: C.EditStructure
  for ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~view_ok: C.Inc.ok(C.runs(~cs), C.runs(~S.edit_structure()), view)
  for events: List<&2, Event>
  for +m: A.Model<cs>
  for h: shows(~cs, ~view, m)
  shows(~cs, ~view, A.play(~cs, ~view, ~press, ~key, events, m))

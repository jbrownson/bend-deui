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

# Turns
# -----
# The screen keeps its own copy of the scene, and is sent the edits a turn
# makes to it.

# LAW: an event's turn holds the model step gives.
law turn_model:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for m: A.Model<cs, view>
  for e: Event
  {A.Turn.model(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, m, e)) == A.step(~cs, ~view, ~press, ~key, ~text, m, e) : A.Model<cs, view>}

# LAW: and its edits take the scene on screen before the event to the one
# after it.
law turn_edits:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for m: A.Model<cs, view>
  for e: Event
  {A.scene(cs, view, A.Turn.model(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, m, e))) == C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, m, e)), A.scene(cs, view, m)) : S.Scene}

# It follows that:

# LAW: the turn of events holds the model play gives.
law turns_model:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for events: List<&2, Event>
  for m: A.Model<cs, view>
  {A.Turn.model(cs, view, A.turns(~cs, ~view, ~press, ~key, ~text, events, m)) == A.play(~cs, ~view, ~press, ~key, ~text, events, m) : A.Model<cs, view>}

# LAW: and its edits take the scene on screen before the events to the one
# after them, so a copy kept by the edits stays the scene on screen.
law turns_edits:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for events: List<&2, Event>
  for +m: A.Model<cs, view>
  {A.scene(cs, view, A.Turn.model(cs, view, A.turns(~cs, ~view, ~press, ~key, ~text, events, m))) == C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turns(~cs, ~view, ~press, ~key, ~text, events, m)), A.scene(cs, view, m)) : S.Scene}

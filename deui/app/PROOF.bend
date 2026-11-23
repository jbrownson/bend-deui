import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ./app.bend as A
import ./LAWS.bend as Laws

def Laws.start_shows(cs, view, state):
  {==}

def Laws.step_shows(cs, view, press, key, text, view_ok, m, e, h):
  match m:
    case A.Model{+state, +shown}:
      %Equal.sym(C.Kept<S.Scene, A.Cache(cs, view)>, shown, C.Cached.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state), h) : {C.Kept.after(~C.runs(~S.edit_structure()), A.Cache(cs, view), C.Cached.df(C.runs(~cs), C.runs(~S.edit_structure()), view)(C.Kept.cache(S.Scene, A.Cache(cs, view), _), A.respond(~cs, ~press, ~key, ~text, state, C.Kept.result(S.Scene, A.Cache(cs, view), shown), e)), C.Kept.result(S.Scene, A.Cache(cs, view), _)) == C.Cached.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(C.run(~cs, A.respond(~cs, ~press, ~key, ~text, state, C.Kept.result(S.Scene, A.Cache(cs, view), shown), e), state)) : C.Kept<S.Scene, A.Cache(cs, view)>}
      view_ok(state, A.respond(~cs, ~press, ~key, ~text, state, C.Kept.result(S.Scene, A.Cache(cs, view), shown), e))

def Laws.play_shows(cs, view, press, key, text, view_ok, events, m, h):
  match events:
    case Nil{}:
      h
    case Con{+e, rest}:
      Laws.play_shows(~cs, ~view, ~press, ~key, ~text, ~view_ok, rest, A.step(~cs, ~view, ~press, ~key, ~text, m, e), Laws.step_shows(~cs, ~view, ~press, ~key, ~text, view_ok, m, e, h))

# Turns
# -----

def Laws.turn_model(cs, view, press, key, text, m, e):
  match m:
    case A.Model{+state, +shown}:
      {==}

def Laws.turn_edits(cs, view, press, key, text, m, e):
  match m:
    case A.Model{+state, +shown}:
      {==}

# Lemma: the turn of events from a turn so far holds the model play gives
# from that turn's model.
law go_model:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for events: List<&2, Event>
  for m: A.Model<cs, view>
  for es: List<&2, S.Edit>
  {A.Turn.model(cs, view, A.turns.go(~cs, ~view, ~press, ~key, ~text, events, A.Turn{m, es})) == A.play(~cs, ~view, ~press, ~key, ~text, events, m) : A.Model<cs, view>}

def go_model(cs, view, press, key, text, events, m, es):
  match events:
    case Nil{}:
      {==}
    case Con{+e, rest}:
      match m:
        case A.Model{+state, +shown}:
          go_model(~cs, ~view, ~press, ~key, ~text, rest, A.Turn.model(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), List.append(&2, S.Edit, es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))))

def Laws.turns_model(cs, view, press, key, text, events, m):
  go_model(~cs, ~view, ~press, ~key, ~text, events, m, Nil{})

# Lemma: if the edits so far take s0 to the scene on screen, the turn of
# events from there has edits that take s0 to the scene on screen after
# them.
law go_edits:
  for ~cs: C.EditStructure
  for ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>
  for ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>
  for ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>
  for ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>
  for events: List<&2, Event>
  for +m: A.Model<cs, view>
  for +es: List<&2, S.Edit>
  for +s0: S.Scene
  for h: {A.scene(cs, view, m) == C.run(~S.edit_structure(), es, s0) : S.Scene}
  {A.scene(cs, view, A.Turn.model(cs, view, A.turns.go(~cs, ~view, ~press, ~key, ~text, events, A.Turn{m, es}))) == C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turns.go(~cs, ~view, ~press, ~key, ~text, events, A.Turn{m, es})), s0) : S.Scene}

def go_edits(cs, view, press, key, text, events, m, es, s0, h):
  match events:
    case Nil{}:
      h
    case Con{+e, rest}:
      match m:
        case A.Model{+state, +shown}:
          go_edits(~cs, ~view, ~press, ~key, ~text, rest, A.Turn.model(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), List.append(&2, S.Edit, es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))), s0,
            Equal.trans(S.Scene, A.scene(cs, view, A.Turn.model(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))), C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), A.scene(cs, view, A.Model{state, shown})), C.run(~S.edit_structure(), List.append(&2, S.Edit, es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))), s0),
              Laws.turn_edits(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e),
              Equal.trans(S.Scene, C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), A.scene(cs, view, A.Model{state, shown})), C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), C.run(~S.edit_structure(), es, s0)), C.run(~S.edit_structure(), List.append(&2, S.Edit, es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))), s0),
                Equal.cong(S.Scene, S.Scene, x => C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), x), A.scene(cs, view, A.Model{state, shown}), C.run(~S.edit_structure(), es, s0), h),
                Equal.sym(S.Scene, C.run(~S.edit_structure(), List.append(&2, S.Edit, es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e))), s0), C.run(~S.edit_structure(), A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), C.run(~S.edit_structure(), es, s0)), C.run_append(~S.edit_structure(), es, A.Turn.edits(cs, view, A.turn(~cs, ~view, ~press, ~key, ~text, A.Model{state, shown}, e)), s0)))))

def Laws.turns_edits(cs, view, press, key, text, events, m):
  go_edits(~cs, ~view, ~press, ~key, ~text, events, m, Nil{}, A.scene(cs, view, m), {==})

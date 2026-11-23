import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ./app.bend as A
import ./LAWS.bend as Laws

def Laws.start_shows(cs, view, state):
  {==}

def Laws.step_shows(cs, view, press, key, view_ok, m, e, h):
  match m:
    case A.Model{+state, +scene}:
      %Equal.sym(S.Scene, scene, C.Inc.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state), h) : {C.run(~S.edit_structure(), C.Inc.df(C.runs(~cs), C.runs(~S.edit_structure()), view)(state, A.respond(~cs, ~press, ~key, state, scene, e)), _) == C.Inc.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(C.run(~cs, A.respond(~cs, ~press, ~key, state, scene, e), state)) : S.Scene}
      view_ok(state, A.respond(~cs, ~press, ~key, state, scene, e))

def Laws.play_shows(cs, view, press, key, view_ok, events, m, h):
  match events:
    case Nil{}:
      h
    case Con{+e, rest}:
      Laws.play_shows(~cs, ~view, ~press, ~key, ~view_ok, rest, A.step(~cs, ~view, ~press, ~key, m, e), Laws.step_shows(~cs, ~view, ~press, ~key, view_ok, m, e, h))

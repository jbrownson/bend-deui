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

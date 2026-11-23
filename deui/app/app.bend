import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../scene/scene.bend as S

# An app: a state, edited as cs says, its view, an incremental function
# from runs of the state's edits to runs of the scene's that keeps what its
# derivative needs, and three
# handlers, fixed code passed as templates. An event becomes a run of edits
# to the state, from what a press hit, which key went down or what was
# typed, and the view's
# derivative turns that run into edits to the scene kept on screen. The
# view itself runs once, at launch.

# What the view keeps for its derivative.
def Cache(-cs: C.EditStructure, view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>) -> Data:
  C.Cached.Cache(C.runs(~cs), C.runs(~S.edit_structure()), view)

# What an app holds between events: its state, and what's shown: the scene
# on screen, with what the view keeps.
type Model<-cs: C.EditStructure, -view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>> is Data:
  Model{state: C.Value(cs), shown: C.Kept<S.Scene, Cache(cs, view)>}

# A pointer's coordinate, in pixels from the window's left or top.
def coordinate(v: F32) -> I.I32:
  I.I32.from_u32(F32.to_u32(F32.max(v, 0.0)))

# A press's edits: the handler's, for what it hit; none, if it hit nothing.
def pressed(~cs: C.EditStructure, ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>,
  state: C.Value(cs), m: Maybe<&2, S.Hit>) -> List<&2, C.Edit(cs)>:
  match m:
    case Some{h}:
      press(state, h)
    case None{}:
      Nil{}

# The edits an event makes to the state: a button pressed down, through
# what it hit in the scene on screen, a key pressed down, or text typed.
# Other events make none.
def respond(~cs: C.EditStructure, ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>,
  ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>, +state: C.Value(cs), scene: S.Scene,
  event: Event) -> List<&2, C.Edit(cs)>:
  match event:
    case Press{id, tool, x, y, time, button, True{}}:
      pressed(~cs, ~press, state, S.hit(scene, 0n, coordinate(x), coordinate(y)))
    case Key{code, True{}}:
      key(state, code)
    case Text{t}:
      text(state, t)
    case e:
      Nil{}

# The model after a run of edits: the state edited, and the scene edited by
# the view's derivative of them, from what the view kept, which it renews.
def edit(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  +state: C.Value(cs), +shown: C.Kept<S.Scene, Cache(cs, view)>, +es: List<&2, C.Edit(cs)>) -> Model<cs, view>:
  Model{C.run(~cs, es, state), C.Kept.after(~C.runs(~S.edit_structure()), Cache(cs, view), C.Cached.df(C.runs(~cs), C.runs(~S.edit_structure()), view)(C.Kept.cache(S.Scene, Cache(cs, view), shown), es), C.Kept.result(S.Scene, Cache(cs, view), shown))}

# The model after an event.
def step(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>,
  m: Model<cs, view>, event: Event) -> Model<cs, view>:
  match m:
    case Model{+state, +shown}:
      edit(~cs, ~view, state, shown, respond(~cs, ~press, ~key, ~text, state, C.Kept.result(S.Scene, Cache(cs, view), shown), event))

# The model at launch: the state, and its view.
def start(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  +state: C.Value(cs)) -> Model<cs, view>:
  Model{state, C.Cached.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state)}

# The model after events, in order.
def play(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>,
  events: List<&2, Event>, m: Model<cs, view>) -> Model<cs, view>:
  match events:
    case Nil{}:
      m
    case Con{e, rest}:
      play(~cs, ~view, ~press, ~key, ~text, rest, step(~cs, ~view, ~press, ~key, ~text, m, e))

# The scene on screen.
def scene(-cs: C.EditStructure, -view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>, m: Model<cs, view>) -> S.Scene:
  match m:
    case Model{state, shown}:
      C.Kept.result(S.Scene, Cache(cs, view), shown)

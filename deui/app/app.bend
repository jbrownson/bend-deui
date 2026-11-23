import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import ../change/change.bend as C
import ../scene/scene.bend as S

# An app: a state, edited as cs says, its view, an incremental function
# from runs of the state's edits to runs of the scene's, and two handlers,
# fixed code passed as templates. An event becomes a run of edits to the
# state, from what a press hit or which key went down, and the view's
# derivative turns that run into edits to the scene kept on screen. The
# view itself runs once, at launch.

# What an app holds between events: its state, and the scene on screen.
type Model<-cs: C.EditStructure> is Data:
  Model{state: C.Value(cs), scene: S.Scene}

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
# what it hit in the scene on screen, or a key pressed down. Other events
# make none.
def respond(~cs: C.EditStructure, ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>,
  ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, +state: C.Value(cs), scene: S.Scene,
  event: Event) -> List<&2, C.Edit(cs)>:
  match event:
    case Press{id, tool, x, y, time, button, True{}}:
      pressed(~cs, ~press, state, S.hit(scene, 0n, coordinate(x), coordinate(y)))
    case Key{code, True{}}:
      key(state, code)
    case e:
      Nil{}

# The model after a run of edits: the state edited, and the scene edited by
# the view's derivative of them.
def edit(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  +state: C.Value(cs), scene: S.Scene, +es: List<&2, C.Edit(cs)>) -> Model<cs>:
  Model{C.run(~cs, es, state), C.run(~S.edit_structure(), C.Inc.df(C.runs(~cs), C.runs(~S.edit_structure()), view)(state, es), scene)}

# The model after an event.
def step(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>,
  m: Model<cs>, event: Event) -> Model<cs>:
  match m:
    case Model{+state, +scene}:
      edit(~cs, ~view, state, scene, respond(~cs, ~press, ~key, state, scene, event))

# The model at launch: the state, and its view.
def start(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  +state: C.Value(cs)) -> Model<cs>:
  Model{state, C.Inc.f(C.runs(~cs), C.runs(~S.edit_structure()), view)(state)}

# The model after events, in order.
def play(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>,
  events: List<&2, Event>, m: Model<cs>) -> Model<cs>:
  match events:
    case Nil{}:
      m
    case Con{e, rest}:
      play(~cs, ~view, ~press, ~key, rest, step(~cs, ~view, ~press, ~key, m, e))

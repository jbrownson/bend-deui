import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ../app/app.bend as D
import ./paint.bend as P
import ../../vendor/amage/Ankra/window.bend as A
import ../../vendor/amage/Ankra/app.bend as Loop
import ../../vendor/amage/Chromi/scene.bend as Sc
import ../../vendor/amage/Chromi/gpu.bend as Gpu
import ../../vendor/amage/Voltra/gpu.bend as V

# An app in a native window: Ankra's window and events, the scene on screen
# drawn on the GPU as a Chromi draw list, which Voltra draws and presents.
# Events go through the app as its step says; the view runs once, at
# launch, and each frame draws the scene kept between events.

# Events
# ------

# Ankra's input as Base's event, where Base has one. The mouse is pointer
# 0; Ankra gives no times, so they're 0.
def event(i: A.Input) -> Maybe<&2, Event>:
  match i:
    case A.PointerDown{x, y, b, m}:
      Some{Press{0, Tool.Mouse{}, x, y, 0, b, True{}}}
    case A.PointerUp{x, y, b, m}:
      Some{Press{0, Tool.Mouse{}, x, y, 0, b, False{}}}
    case A.PointerMoved{x, y}:
      Some{Move{0, Tool.Mouse{}, x, y, 0}}
    case A.KeyDown{c, r, m}:
      Some{Key{c, True{}}}
    case A.KeyUp{c, m}:
      Some{Key{c, False{}}}
    case A.TextTyped{t}:
      Some{Text{t}}
    case A.Wheel{x, y, dx, dy}:
      Some{Scroll{x, y, dx, dy}}
    case A.CloseRequested{}:
      Some{Close{}}
    case i:
      None{}

def events.add(m: Maybe<&2, Event>, rest: List<&2, Event>) -> List<&2, Event>:
  match m:
    case Some{e}:
      Con{e, rest}
    case None{}:
      rest

def events(ins: List<&2, A.Input>) -> List<&2, Event>:
  match ins:
    case Nil{}:
      Nil{}
    case Con{i, rest}:
      events.add(event(i), events(rest))

# Whether the events ask the window to close.
def closing(es: List<&2, Event>) -> Bool:
  match es:
    case Nil{}:
      False{}
    case Con{e, rest}:
      match e:
        case Close{}:
          True{}
        case e:
          closing(rest)

# The loop
# --------

def resized(m: Maybe<&2, A.Size>, +r: Gpu.Renderer) -> IO(Gpu.Renderer):
  match m:
    case None{}:
      IO.pure(Gpu.Renderer, r)
    case Some{A.Size{w, h}}:
      Gpu.resize(r, w, h)

# The app's answer to a batch: the model after its events, drawn again, or
# stopping when the window closes.
def next(-cs: C.EditStructure, close: Bool, r: Gpu.Renderer, m: D.Model<cs>) -> Loop.Step<(D.Model<cs> & Gpu.Renderer)>:
  match close:
    case True{}:
      Loop.Stop{(m, r)}
    case False{}:
      Loop.Redraw{(m, r)}

def update(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>,
  win: A.Win, batch: List<&2, A.Input>, st: D.Model<cs> & Gpu.Renderer) -> IO(Loop.Step<(D.Model<cs> & Gpu.Renderer)>):
  (m, r) = st
  +ins = batch
  +es = events(ins)
  do IO<Loop.Step<(D.Model<cs> & Gpu.Renderer)>>:
    +r1 : Gpu.Renderer <- resized(A.resized(ins, None{}), r)
    return next(cs, closing(es), r1, D.play(~cs, ~view, ~press, ~key, es, m))

# Another frame is owed when the swapchain was rebuilt while presenting.
def drawn(-cs: C.EditStructure, pending: Bool, r: Gpu.Renderer, m: D.Model<cs>) -> Loop.Step<(D.Model<cs> & Gpu.Renderer)>:
  match pending:
    case True{}:
      Loop.Redraw{(m, r)}
    case False{}:
      Loop.Keep{(m, r)}

def scene.of(-cs: C.EditStructure, m: D.Model<cs>) -> S.Scene:
  match m:
    case D.Model{state, scene}:
      scene

# The frame for a target of the given size.
def sized(s: S.Scene, size: V.Size, +bg: U32) -> Sc.Scene:
  V.Size{w, h} = size
  P.frame(s, w, h, bg)

def draw(~cs: C.EditStructure, ~bg: U32, win: A.Win, st: D.Model<cs> & Gpu.Renderer) ->
  IO(Loop.Step<(D.Model<cs> & Gpu.Renderer)>):
  (+m, +r) = st
  do IO<Loop.Step<(D.Model<cs> & Gpu.Renderer)>>:
    +r1 : Gpu.Renderer <- Gpu.draw(r, sized(scene.of(cs, m), Gpu.target_size(r), bg))
    return drawn(cs, Gpu.pending(r1), r1, m)

# The GPU objects go before the window they were made from.
def finish(-cs: C.EditStructure, end: A.Win & D.Model<cs> & Gpu.Renderer) -> IO(Unit):
  (win, m, r) = end
  do IO<Unit>:
    +report : V.Report <- Gpu.close(r)
    Unit <- IO.print(V.report.show(report))
    +left : U32 <- A.close(win)
    return Unit{}

# Runs an app in a window of the given size on a background of `bg`
# (0xRRGGBB), from `state`, until the window closes.
def run(~cs: C.EditStructure, ~view: C.Inc<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>,
  ~bg: U32, title: String, +width: U32, +height: U32, +state: C.Value(cs)) -> IO(Unit):
  do IO<Unit>:
    +win : A.Win <- IO.try(A.Win, A.open(A.options(title, width, height)))
    +native : List<&2, U32> <- A.native(win)
    +r : Gpu.Renderer <- Gpu.open(native, width, height, True{})
    end : A.Win & D.Model<cs> & Gpu.Renderer <- Loop.run(~(D.Model<cs> & Gpu.Renderer),
      ~(w => b => st => update(~cs, ~view, ~press, ~key, w, b, st)),
      ~(w => st => draw(~cs, ~bg, w, st)), win, (D.start(~cs, ~view, state), r))
    finish(cs, end)

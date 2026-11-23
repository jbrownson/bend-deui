import Base
import ../change/change.bend as C
import ../scene/scene.bend as S
import ../app/app.bend as D
import ./screen.bend as W

# An app in a native window: the screen's events go through the app as its
# step says, and each frame draws the scene kept between events. The view
# runs once, at launch.

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

# Says why labels are left out, if the font didn't open.
def font_note(r: Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  match r:
    case Done{u}:
      IO.pure(Unit, Unit{})
    case Fail{(code, message)}:
      IO.print(String.concat(["no font, so labels are left out: ", message, "\n"]))

# Draws the scene on screen, waits for events, and plays them through the
# app, until the window closes, or after fuel turns: Bend requires every
# loop to end.
def loop(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>,
  ~bg: U32, fuel: Nat, close: Bool, +win: U32, +m: D.Model<cs, view>) -> IO(Unit):
  match fuel close:
    case _ True{}:
      IO.pure(Unit, Unit{})
    case 0n False{}:
      IO.pure(Unit, Unit{})
    case 1n+p False{}:
      do IO<Unit>:
        Unit <- IO.try(Unit, W.screen_draw(win, bg, W.frame(D.scene(cs, view, m))))
        wss : List<&2, List<&2, U32>> <- IO.try(List<&2, List<&2, U32>>, W.screen_wait(win, 4294967295))
        +es : List<&2, Event> = W.events(wss)
        loop(~cs, ~view, ~press, ~key, ~text, ~bg, p, closing(es), win, D.play(~cs, ~view, ~press, ~key, ~text, es, m))

# Runs an app in a window of the given size on a background of `bg`
# (0xRRGGBB), its labels in the TrueType font at font_path, from `state`,
# until the window closes.
def run(~cs: C.EditStructure, ~view: C.Cached<C.runs(~cs), C.runs(~S.edit_structure())>,
  ~press: C.Value(cs) -> S.Hit -> List<&2, C.Edit(cs)>, ~key: C.Value(cs) -> U32 -> List<&2, C.Edit(cs)>, ~text: C.Value(cs) -> String -> List<&2, C.Edit(cs)>,
  ~bg: U32, title: String, font_path: String, +width: U32, +height: U32, +state: C.Value(cs)) -> IO(Unit):
  do IO<Unit>:
    +win : U32 <- IO.try(U32, W.screen_open(title, width, height))
    r : Result<&1, &1, U32 & String, Unit> <- W.screen_font(win, font_path)
    Unit <- font_note(r)
    Unit <- loop(~cs, ~view, ~press, ~key, ~text, ~bg, 4294967295n, False{}, win, D.start(~cs, ~view, state))
    IO.try(Unit, W.screen_close(win))

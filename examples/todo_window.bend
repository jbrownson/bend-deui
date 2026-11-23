import Base
import ../deui/window/window.bend as W
import ./todo.bend as T

# The to-do list in a window. Build it natively:
#   bend examples/todo_window.bend -o todo && ./todo
# The font is Liberation Sans where Arch puts it; another path works too.
def main() -> IO(Unit):
  W.run(~T.items_edits(), ~T.view(), ~T.handlers.press, ~T.handlers.key, ~T.handlers.text, ~1579292,
    "deui to-do", "/usr/share/fonts/liberation/LiberationSans-Regular.ttf", 360, 400, T.items())

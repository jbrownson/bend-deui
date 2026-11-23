import Base
import ../deui/column/column.bend as K
import ../deui/window/window.bend as W
import ./rows.bend as R

# The rows app in a window: click a row to delete it, press "a" to add one
# at the top. Build it natively: bend examples/rows_window.bend -o rows && ./rows
def main() -> IO(Unit):
  W.run(~K.rows_edits(), ~K.inc(), ~R.press, ~R.key, ~2106408, "deui rows", 400, 300, R.rows())

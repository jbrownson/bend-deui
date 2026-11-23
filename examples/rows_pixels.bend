import Base
import ../deui/column/column.bend as K
import ../deui/app/app.bend as A
import ../deui/window/paint.bend as P
import ../vendor/amage/Chromi/replay.bend as Rp
import ./rows.bend as R

# The rows app's scene after its events, drawn on the CPU as the window
# draws it on the GPU, beside the column drawn again from the rows left:
# every pixel is the same, and a pixel in each row has that row's color.

def width() -> U32:
  200

# The pixels as a list that can be read more than once.
def copyable(xs: List<U32>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      h <> copyable(t)

def pixel(+px: List<&2, U32>, x: U32, y: U32) -> U32:
  Maybe.default(&2, U32, List.get(&2, U32, px, U32.to_nat(((y * width() : U32) + x : U32))), 0)

def compare(+a: List<&2, U32>, +b: List<&2, U32>) -> String:
  String.concat(["row at y 2: ", U32.show(pixel(a, 10, 2)), " (0x000009ff = ", U32.show(2559), ")\n",
    "row at y 20: ", U32.show(pixel(a, 10, 20)), " (0x000003ff = ", U32.show(1023), ")\n",
    "the same as drawing the rows again, at those pixels: ", R.yes(Bool.and(U32.is_eq(pixel(a, 10, 2), pixel(b, 10, 2)), U32.is_eq(pixel(a, 10, 20), pixel(b, 10, 20)))), "\n"])

def both(ra: Result<&1, &1, U32 & String, Array<U32>>, rb: Result<&1, &1, U32 & String, Array<U32>>) -> String:
  match ra rb:
    case Done{a} Done{b}:
      compare(copyable(Array.to_list(~U32, a)), copyable(Array.to_list(~U32, b)))
    case ra rb:
      "a frame failed to draw\n"

def report(+m: A.Model<K.rows_edits(), R.view()>) -> String:
  match m:
    case A.Model{+state, shown}:
      both(Rp.pixels(P.frame(A.scene(K.rows_edits(), R.view(), m), None{}, width(), 60, 2106408)), Rp.pixels(P.frame(K.view(state), None{}, width(), 60, 2106408)))

def main() -> IO(Unit):
  IO.print(report(R.model()))

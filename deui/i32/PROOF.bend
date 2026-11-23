import Base
import 0x4eed9d7ac6ece61523d747a9d804e4f0/int.bend as I
import 0x15432fae482a0916f1cfffa8b5e1a335/nat.bend as MN
import 0x15432fae482a0916f1cfffa8b5e1a335/u32.bend as MU
import ./LAWS.bend as Laws

# U32 addition, through Nat: bend-mathlib says it wraps modulo 2^32, and
# that two U32s with the same Nat are the same.

# Lemma: reducing the left operand first doesn't change a remainder.
law mod_add_left:
  for +a: Nat
  for +b: Nat
  for +m: Nat
  {Nat.mod(Nat.add(a, b), m) == Nat.mod(Nat.add(Nat.mod(a, m), b), m) : Nat}

def mod_add_left(a, b, m):
  %MN.mod_add_div(a, m) : {Nat.mod(Nat.add(_, b), m) == Nat.mod(Nat.add(Nat.mod(a, m), b), m) : Nat}
  %MN.add_right_comm(Nat.mod(a, m), b, Nat.mul(m, Nat.div(a, m))) : {Nat.mod(_, m) == Nat.mod(Nat.add(Nat.mod(a, m), b), m) : Nat}
  %MN.add_mul_mod_self_left_sym(Nat.add(Nat.mod(a, m), b), m, Nat.div(a, m)) : {_ == Nat.mod(Nat.add(Nat.mod(a, m), b), m) : Nat}
  {==}

# Lemma: reducing the right operand first doesn't change a remainder.
law mod_add_right:
  for +a: Nat
  for +b: Nat
  for +m: Nat
  {Nat.mod(Nat.add(a, b), m) == Nat.mod(Nat.add(a, Nat.mod(b, m)), m) : Nat}

def mod_add_right(a, b, m):
  %MN.mod_add_div(b, m) : {Nat.mod(Nat.add(a, _), m) == Nat.mod(Nat.add(a, Nat.mod(b, m)), m) : Nat}
  %MN.add_assoc(a, Nat.mod(b, m), Nat.mul(m, Nat.div(b, m))) : {Nat.mod(_, m) == Nat.mod(Nat.add(a, Nat.mod(b, m)), m) : Nat}
  %MN.add_mul_mod_self_left_sym(Nat.add(a, Nat.mod(b, m)), m, Nat.div(b, m)) : {_ == Nat.mod(Nat.add(a, Nat.mod(b, m)), m) : Nat}
  {==}

# Lemma: U32 addition, through Nat, doesn't depend on which two are added
# first.
law u32_add_assoc_nat:
  for +a: U32
  for +b: U32
  for +c: U32
  {U32.to_nat(U32.add(U32.add(a, b), c)) == U32.to_nat(U32.add(a, U32.add(b, c))) : Nat}

def u32_add_assoc_nat(a, b, c):
  %MU.u32_add_wrap_sym(U32.add(a, b), c) : {_ == U32.to_nat(U32.add(a, U32.add(b, c))) : Nat}
  %MU.u32_add_wrap_sym(a, b) : {Nat.mod(Nat.add(_, U32.to_nat(c)), Nat.pow(2n, 32n)) == U32.to_nat(U32.add(a, U32.add(b, c))) : Nat}
  %mod_add_left(Nat.add(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(c), Nat.pow(2n, 32n)) : {_ == U32.to_nat(U32.add(a, U32.add(b, c))) : Nat}
  %MU.u32_add_wrap_sym(a, U32.add(b, c)) : {Nat.mod(Nat.add(Nat.add(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(c)), Nat.pow(2n, 32n)) == _ : Nat}
  %MU.u32_add_wrap_sym(b, c) : {Nat.mod(Nat.add(Nat.add(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(c)), Nat.pow(2n, 32n)) == Nat.mod(Nat.add(U32.to_nat(a), _), Nat.pow(2n, 32n)) : Nat}
  %mod_add_right(U32.to_nat(a), Nat.add(U32.to_nat(b), U32.to_nat(c)), Nat.pow(2n, 32n)) : {Nat.mod(Nat.add(Nat.add(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(c)), Nat.pow(2n, 32n)) == _ : Nat}
  %MN.add_assoc(U32.to_nat(a), U32.to_nat(b), U32.to_nat(c)) : {Nat.mod(Nat.add(Nat.add(U32.to_nat(a), U32.to_nat(b)), U32.to_nat(c)), Nat.pow(2n, 32n)) == Nat.mod(_, Nat.pow(2n, 32n)) : Nat}
  {==}

# Lemma: U32 addition doesn't depend on which two are added first.
law u32_add_assoc:
  for +a: U32
  for +b: U32
  for +c: U32
  {U32.add(U32.add(a, b), c) == U32.add(a, U32.add(b, c)) : U32}

def u32_add_assoc(a, b, c):
  MU.u32_to_nat_inj(U32.add(U32.add(a, b), c), U32.add(a, U32.add(b, c)), u32_add_assoc_nat(a, b, c))

# I32
# ---

def Laws.add_comm(a, b):
  match a b:
    case I.I32{x} I.I32{y}:
      %U32.add_comm(x, y) : {I.I32{U32.add(x, y)} == I.I32{_} : I.I32}
      {==}

def Laws.add_assoc(a, b, c):
  match a b c:
    case I.I32{x} I.I32{y} I.I32{z}:
      %u32_add_assoc(x, y, z) : {I.I32{U32.add(U32.add(x, y), z)} == I.I32{_} : I.I32}
      {==}

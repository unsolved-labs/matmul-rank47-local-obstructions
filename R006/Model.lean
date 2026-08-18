import R006.GeneratedData

namespace R006

open GeneratedData

abbrev Factors := Array (Array (Array Bool))
abbrev Coord := GeneratedData.Coord
abbrev Edit := GeneratedData.Edit

/-- A frozen factor-support bit, with out-of-range indices defaulting to false. -/
def factorBit (f : Factors) (q r i : Nat) : Bool :=
  ((f.getD q #[]).getD r #[]).getD i false

def coordA (x : Coord) : Nat := x.1
def coordB (x : Coord) : Nat := x.2.1
def coordC (x : Coord) : Nat := x.2.2

/-- Bounds defining the 16×16×16 tensor-coordinate cube. -/
def coordValid (x : Coord) : Bool :=
  decide (coordA x < 16) && decide (coordB x < 16) && decide (coordC x < 16)

def editQ (e : Edit) : Nat := e.1
def editR (e : Edit) : Nat := e.2.1
def editI (e : Edit) : Nat := e.2.2

def editMatches (e : Edit) (q r i : Nat) : Bool :=
  (editQ e == q) && (editR e == r) && (editI e == i)

/-- Support bit after applying a finite list of factor-entry toggles. -/
def factorBitAfter (f : Factors) (edits : Array Edit) (q r i : Nat) : Bool :=
  edits.foldl (fun b e => if editMatches e q r i then !b else b) (factorBit f q r i)

/-- The 4×4 matrix-multiplication target bit at flattened tensor coordinate `(a,b,c)`. -/
def targetBit (x : Coord) : Bool :=
  let a := coordA x
  let b := coordB x
  let c := coordC x
  let i := a / 4
  let j := a % 4
  let j2 := b / 4
  let k := b % 4
  (j == j2) && (c == 4 * k + i)

/-- Decode a factor-entry variable index in the fixed `3×47×16=2256` space. -/
def decodeVar (v : Nat) : Edit :=
  let q := v / (47 * 16)
  let rem := v % (47 * 16)
  (q, rem / 16, rem % 16)

end R006

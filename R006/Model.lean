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

private def applyEditBit (q r i : Nat) (b : Bool) (e : Edit) : Bool :=
  if editMatches e q r i then !b else b

/-- Support bit after applying a finite list of factor-entry toggles. -/
def factorBitAfter (f : Factors) (edits : Array Edit) (q r i : Nat) : Bool :=
  edits.toList.foldl (applyEditBit q r i) (factorBit f q r i)

@[simp] theorem factorBitAfter_empty (f : Factors) (q r i : Nat) :
    factorBitAfter f #[] q r i = factorBit f q r i := by
  rfl

/-- Appending one support edit toggles exactly its named factor entry. -/
theorem factorBitAfter_push (f : Factors) (edits : Array Edit) (e : Edit) (q r i : Nat) :
    factorBitAfter f (edits.push e) q r i =
      if editMatches e q r i then !(factorBitAfter f edits q r i)
      else factorBitAfter f edits q r i := by
  simp [factorBitAfter, applyEditBit, List.foldl_append]

/-- An edit with a different rank index leaves this factor bit unchanged. -/
theorem factorBitAfter_push_of_rank_ne
    (f : Factors) (edits : Array Edit) (e : Edit) (q r i : Nat)
    (hr : editR e ≠ r) :
    factorBitAfter f (edits.push e) q r i = factorBitAfter f edits q r i := by
  rw [factorBitAfter_push]
  have hm : editMatches e q r i = false := by
    simp [editMatches, hr]
  simp [hm]

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

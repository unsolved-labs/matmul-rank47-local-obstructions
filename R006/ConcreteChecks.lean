import R006.Algebra
import R006.GeneratedData

namespace R006

open GeneratedData

abbrev Factors := Array (Array (Array Bool))
abbrev Coord := GeneratedData.Coord

private def factorBit (f : Factors) (q r i : Nat) : Bool :=
  ((f.getD q #[]).getD r #[]).getD i false

private def coordA (x : Coord) : Nat := x.1
private def coordB (x : Coord) : Nat := x.2.1
private def coordC (x : Coord) : Nat := x.2.2

private def targetBit (x : Coord) : Bool :=
  let a := coordA x
  let b := coordB x
  let c := coordC x
  let i := a / 4
  let j := a % 4
  let j2 := b / 4
  let k := b % 4
  (j == j2) && (c == 4 * k + i)

private def activeCount (f : Factors) (x : Coord) : Nat :=
  (List.range 47).foldl (fun s r =>
    if factorBit f 0 r (coordA x) && factorBit f 1 r (coordB x) &&
        factorBit f 2 r (coordC x) then s + 1 else s) 0

private def decodeVar (v : Nat) : Nat × Nat × Nat :=
  let q := v / (47 * 16)
  let rem := v % (47 * 16)
  (q, rem / 16, rem % 16)

/-- Coefficient of a lift-correction bit in one first-order mod-4 equation. -/
def mod4Coeff (f : Factors) (x : Coord) (v : Nat) : Bool :=
  let d := decodeVar v
  let q := d.1
  let r := d.2.1
  let i := d.2.2
  if q == 0 then
    (i == coordA x) && factorBit f 1 r (coordB x) && factorBit f 2 r (coordC x)
  else if q == 1 then
    (i == coordB x) && factorBit f 0 r (coordA x) && factorBit f 2 r (coordC x)
  else if q == 2 then
    (i == coordC x) && factorBit f 0 r (coordA x) && factorBit f 1 r (coordB x)
  else false

/-- Right-hand side of the first-order mod-4 lifting equation, represented in `F₂`. -/
def mod4Rhs (f : Factors) (x : Coord) : Bool :=
  let s := activeCount f x
  let t := if targetBit x then 1 else 0
  (((s - t) / 2) % 2) == 1

private def certCoeffXor (f : Factors) (cert : Array Coord) (v : Nat) : Bool :=
  cert.foldl (fun acc x => Bool.xor acc (mod4Coeff f x v)) false

private def certRhsXor (f : Factors) (cert : Array Coord) : Bool :=
  cert.foldl (fun acc x => Bool.xor acc (mod4Rhs f x)) false

/-- Executable check that selected equations XOR to coefficient vector zero and RHS one. -/
def checkMod4Certificate (f : Factors) (cert : Array Coord) : Bool :=
  (List.range (3 * 47 * 16)).all (fun v => !(certCoeffXor f cert v)) &&
    certRhsXor f cert

/-- The frozen 523-equation AlphaTensor mod-4 certificate is recomputed in Lean. -/
set_option maxRecDepth 100000 in
set_option maxHeartbeats 200000000 in
theorem alpha_mod4_certificate_checked :
    checkMod4Certificate alphaFactors alphaMod4Certificate = true := by
  decide

/-- The frozen 292-equation Kauers–Moosbauer mod-4 certificate is recomputed in Lean. -/
set_option maxRecDepth 100000 in
set_option maxHeartbeats 200000000 in
theorem flips_mod4_certificate_checked :
    checkMod4Certificate flipsFactors flipsMod4Certificate = true := by
  decide

end R006

import R006.Algebra
import R006.Model

namespace R006

open GeneratedData

/-- Integer number of active binary rank-one monomials at one tensor coordinate. -/
def baseActiveCount (f : Factors) (x : Coord) : Nat :=
  (List.range 47).foldl (fun s r =>
    if factorBit f 0 r (coordA x) && factorBit f 1 r (coordB x) &&
        factorBit f 2 r (coordC x) then s + 1 else s) 0

/-- Coefficient of a lift-correction bit in one first-order mod-4 equation. -/
def mod4Coeff (f : Factors) (x : Coord) (v : Nat) : Bool :=
  let d := decodeVar v
  let q := editQ d
  let r := editR d
  let i := editI d
  if q == 0 then
    (i == coordA x) && factorBit f 1 r (coordB x) && factorBit f 2 r (coordC x)
  else if q == 1 then
    (i == coordB x) && factorBit f 0 r (coordA x) && factorBit f 2 r (coordC x)
  else if q == 2 then
    (i == coordC x) && factorBit f 0 r (coordA x) && factorBit f 1 r (coordB x)
  else false

/-- Right-hand side of the first-order mod-4 lifting equation, represented in `F₂`. -/
def mod4Rhs (f : Factors) (x : Coord) : Bool :=
  let s := baseActiveCount f x
  let t := if targetBit x then 1 else 0
  (((s - t) / 2) % 2) == 1

/-- XOR of one lift-variable coefficient through a certificate coordinate list. -/
def mod4CoeffXorList (f : Factors) (v : Nat) : List Coord → Bool
  | [] => false
  | x :: xs => mod4Coeff f x v ^^ mod4CoeffXorList f v xs

/-- XOR of the selected mod-4 lifting right-hand sides. -/
def mod4RhsXorList (f : Factors) : List Coord → Bool
  | [] => false
  | x :: xs => mod4Rhs f x ^^ mod4RhsXorList f xs

/-- Coefficient XOR for a concrete frozen certificate. -/
def certCoeffXor (f : Factors) (cert : Array Coord) (v : Nat) : Bool :=
  mod4CoeffXorList f v cert.toList

/-- RHS XOR for a concrete frozen certificate. -/
def certRhsXor (f : Factors) (cert : Array Coord) : Bool :=
  mod4RhsXorList f cert.toList

/-- Executable check that all selected coordinates are valid, coefficients XOR to zero, and RHS XORs to one. -/
def checkMod4Certificate (f : Factors) (cert : Array Coord) : Bool :=
  cert.all coordValid &&
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

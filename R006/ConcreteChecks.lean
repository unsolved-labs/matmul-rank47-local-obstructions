import R006.Algebra
import R006.Model

namespace R006

open GeneratedData

set_option maxRecDepth 100000
set_option maxHeartbeats 200000000

/-- Binary activity bits of the 47 rank-one monomials at one coordinate. -/
def baseActiveBits (f : Factors) (x : Coord) : List Bool :=
  (List.range 47).map (fun r =>
    factorBit f 0 r (coordA x) && factorBit f 1 r (coordB x) &&
      factorBit f 2 r (coordC x))

/-- Integer number of active binary rank-one monomials at one tensor coordinate. -/
def baseActiveCount (f : Factors) (x : Coord) : Nat :=
  (baseActiveBits f x).count true

/-- There are at most 47 active binary monomials. -/
theorem baseActiveCount_le_47 (f : Factors) (x : Coord) : baseActiveCount f x ≤ 47 := by
  have h := List.count_le_length true (baseActiveBits f x)
  simpa [baseActiveCount, baseActiveBits] using h

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

/-- Fixed correction-variable index in the 3×47×16 mod-4 lifting space. -/
def mod4VarIndex (q r i : Nat) : Nat :=
  (q * 47 + r) * 16 + i

/-- Sparse 2,256-bit first-order coefficient mask contributed by one rank-one term.
    This is the exact representation used by the released Python verifier. -/
def mod4RankMask (f : Factors) (x : Coord) (r : Nat) : Nat :=
  let a := coordA x
  let b := coordB x
  let c := coordC x
  let u := factorBit f 0 r a
  let v := factorBit f 1 r b
  let w := factorBit f 2 r c
  (if v && w then 1 <<< mod4VarIndex 0 r a else 0) ^^^
    (if u && w then 1 <<< mod4VarIndex 1 r b else 0) ^^^
    (if u && v then 1 <<< mod4VarIndex 2 r c else 0)

/-- XOR sparse rank masks for one tensor equation. -/
def mod4RowMaskList (f : Factors) (x : Coord) : List Nat → Nat
  | [] => 0
  | r :: rs => mod4RankMask f x r ^^^ mod4RowMaskList f x rs

/-- Sparse first-order coefficient row for one tensor equation. -/
def mod4RowMask (f : Factors) (x : Coord) : Nat :=
  mod4RowMaskList f x (List.range 47)

/-- XOR sparse equation rows over a certificate coordinate list. -/
def mod4CertificateMaskList (f : Factors) : List Coord → Nat
  | [] => 0
  | x :: xs => mod4RowMask f x ^^^ mod4CertificateMaskList f xs

/-- Sparse accumulated coefficient mask for a frozen certificate. -/
def mod4CertificateMask (f : Factors) (cert : Array Coord) : Nat :=
  mod4CertificateMaskList f cert.toList

/-- Right-hand side of the first-order mod-4 lifting equation, represented in `F₂`. -/
def mod4Rhs (f : Factors) (x : Coord) : Bool :=
  let s := baseActiveCount f x
  let t := if targetBit x then 1 else 0
  (((s - t) / 2) % 2) == 1

/-- XOR of the selected mod-4 lifting right-hand sides. -/
def mod4RhsXorList (f : Factors) : List Coord → Bool
  | [] => false
  | x :: xs => mod4Rhs f x ^^ mod4RhsXorList f xs

/-- RHS XOR for a concrete frozen certificate. -/
def certRhsXor (f : Factors) (cert : Array Coord) : Bool :=
  mod4RhsXorList f cert.toList

/-- Executable sparse check: all selected coordinates are valid, their 2,256-bit
    coefficient rows XOR to zero, and their RHS bits XOR to one. -/
def checkMod4Certificate (f : Factors) (cert : Array Coord) : Bool :=
  cert.toList.all coordValid &&
    (decide (mod4CertificateMask f cert = 0) && certRhsXor f cert)

/-- The frozen 523-equation AlphaTensor mod-4 certificate is recomputed in Lean. -/
theorem alpha_mod4_certificate_checked :
    checkMod4Certificate alphaFactors alphaMod4Certificate = true := by
  decide

/-- The frozen 292-equation Kauers–Moosbauer mod-4 certificate is recomputed in Lean. -/
theorem flips_mod4_certificate_checked :
    checkMod4Certificate flipsFactors flipsMod4Certificate = true := by
  decide

end R006

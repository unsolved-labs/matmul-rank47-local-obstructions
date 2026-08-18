import R006.F3Parity
import R006.Model

namespace R006

open GeneratedData

/-- Whether rank-one term `r` is active at a tensor coordinate after support edits. -/
def activeRank (f : Factors) (edits : Array Edit) (x : Coord) (r : Nat) : Bool :=
  factorBitAfter f edits 0 r (coordA x) &&
    factorBitAfter f edits 1 r (coordB x) &&
    factorBitAfter f edits 2 r (coordC x)

/-- Active rank-one terms at one tensor coordinate. -/
def activeRanks (f : Factors) (edits : Array Edit) (x : Coord) : List Nat :=
  (List.range 47).filter (activeRank f edits x)

/-- Number of active rank-one monomials at one tensor coordinate. -/
def f3ActiveCount (f : Factors) (edits : Array Edit) (x : Coord) : Nat :=
  (activeRanks f edits x).length

def negativeResidue (k t : Nat) : Nat :=
  (t + 3 - (k % 3)) % 3

/-- The exact bounded-coordinate criterion used to emit an F3 parity equation. -/
def parityInformative (k t : Nat) : Bool :=
  if k == 0 then t == 1
  else if decide (k > 4) then false
  else
    let n := negativeResidue k t
    decide (n <= k) && decide (n + 3 > k)

/-- Forced parity of the number of negative active monomials. -/
def parityRhs (k t : Nat) : Bool :=
  if k == 0 then t == 1
  else (negativeResidue k t) % 2 == 1

/-- Fixed sign-variable index in the 3×47×16 space. -/
def variableIndex (q r i : Nat) : Nat :=
  (q * 47 + r) * 16 + i

/-- Three sign-variable bits occurring in one active rank-one monomial. -/
def rankParityMask (x : Coord) (r : Nat) : Nat :=
  (1 <<< variableIndex 0 r (coordA x)) ^^^
    (1 <<< variableIndex 1 r (coordB x)) ^^^
    (1 <<< variableIndex 2 r (coordC x))

/-- XOR mask contributed by a list of active rank-one terms. -/
def ranksParityMask (x : Coord) : List Nat → Nat
  | [] => 0
  | r :: rs => rankParityMask x r ^^^ ranksParityMask x rs

/-- Fixed-space 2,256-bit coefficient mask for one necessary F3 parity equation. -/
def f3ParityMask (f : Factors) (edits : Array Edit) (x : Coord) : Nat :=
  ranksParityMask x (activeRanks f edits x)

/-- Reconstruct one necessary parity equation, when the negative count is uniquely determined. -/
def f3ParityEquation (f : Factors) (edits : Array Edit) (x : Coord) : Option (Nat × Bool) :=
  let k := f3ActiveCount f edits x
  let t := if targetBit x then 1 else 0
  if parityInformative k t then some (f3ParityMask f edits x, parityRhs k t) else none

/-- Recursive accumulator for a parity contradiction certificate. -/
def f3CertificateAccumList
    (f : Factors) (edits : Array Edit) : List Coord → Option (Nat × Bool)
  | [] => some (0, false)
  | x :: xs =>
      match f3ParityEquation f edits x, f3CertificateAccumList f edits xs with
      | some (m, y), some (m', y') => some (m ^^^ m', Bool.xor y y')
      | _, _ => none

/-- Accumulated coefficient mask and RHS for a concrete parity certificate. -/
def f3CertificateAccum
    (f : Factors) (edits : Array Edit) (cert : Array Coord) : Option (Nat × Bool) :=
  f3CertificateAccumList f edits cert.toList

/-- Tensor-coordinate bounds used by every released certificate. -/
def coordValid (x : Coord) : Bool :=
  decide (coordA x < 16) && decide (coordB x < 16) && decide (coordC x < 16)

/-- Exact executable contradiction check for a list of F3 parity coordinates. -/
def checkF3Certificate (f : Factors) (edits : Array Edit) (cert : Array Coord) : Bool :=
  cert.all coordValid && decide (f3CertificateAccum f edits cert = some (0, true))

/-- Whether toggling one factor entry can change a monomial used by a certificate. -/
def affectsCertificate
    (f : Factors) (edits : Array Edit) (e : Edit) (cert : Array Coord) : Bool :=
  cert.any (fun x =>
    let q := editQ e
    let r := editR e
    let i := editI e
    if q == 0 then
      (coordA x == i) && factorBitAfter f edits 1 r (coordB x) &&
        factorBitAfter f edits 2 r (coordC x)
    else if q == 1 then
      (coordB x == i) && factorBitAfter f edits 0 r (coordA x) &&
        factorBitAfter f edits 2 r (coordC x)
    else if q == 2 then
      (coordC x == i) && factorBitAfter f edits 0 r (coordA x) &&
        factorBitAfter f edits 1 r (coordB x)
    else false)

/-- Every frozen AlphaTensor base-support parity row XORs to contradiction in Lean. -/
set_option maxRecDepth 100000 in
theorem alpha_f3_base_certificate_checked :
    checkF3Certificate alphaFactors #[] alphaF3BaseCertificate = true := by
  decide

/-- Every frozen Kauers–Moosbauer base-support parity row XORs to contradiction in Lean. -/
set_option maxRecDepth 100000 in
theorem flips_f3_base_certificate_checked :
    checkF3Certificate flipsFactors #[] flipsF3BaseCertificate = true := by
  decide

private def checkEditCertificate (f : Factors) (item : EditCertificate) : Bool :=
  checkF3Certificate f #[item.edit] item.equations

/-- All 70 dedicated AlphaTensor distance-one certificates are reconstructed and checked in Lean. -/
set_option maxRecDepth 100000 in
set_option maxHeartbeats 200000000 in
theorem alpha_f3_dedicated_distance1_checked :
    alphaF3EditCertificates.all (checkEditCertificate alphaFactors) = true := by
  decide

/-- All 113 dedicated Kauers–Moosbauer distance-one certificates are reconstructed and checked in Lean. -/
set_option maxRecDepth 100000 in
set_option maxHeartbeats 200000000 in
theorem flips_f3_dedicated_distance1_checked :
    flipsF3EditCertificates.all (checkEditCertificate flipsFactors) = true := by
  decide

end R006

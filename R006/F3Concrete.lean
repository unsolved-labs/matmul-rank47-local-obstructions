import R006.F3Parity
import R006.Model

namespace R006

open GeneratedData

private def activeRank (f : Factors) (edits : Array Edit) (x : Coord) (r : Nat) : Bool :=
  factorBitAfter f edits 0 r (coordA x) &&
    factorBitAfter f edits 1 r (coordB x) &&
    factorBitAfter f edits 2 r (coordC x)

/-- Number of active rank-one monomials at one tensor coordinate. -/
def f3ActiveCount (f : Factors) (edits : Array Edit) (x : Coord) : Nat :=
  (List.range 47).foldl (fun k r => if activeRank f edits x r then k + 1 else k) 0

private def negativeResidue (k t : Nat) : Nat :=
  (t + 3 - (k % 3)) % 3

private def parityInformative (k t : Nat) : Bool :=
  if k == 0 then t == 1
  else if k > 4 then false
  else
    let n := negativeResidue k t
    (n <= k) && (n + 3 > k)

private def parityRhs (k t : Nat) : Bool :=
  if k == 0 then t == 1
  else (negativeResidue k t) % 2 == 1

private def variableIndex (q r i : Nat) : Nat :=
  (q * 47 + r) * 16 + i

/-- Fixed-space 2,256-bit coefficient mask for one necessary F3 parity equation. -/
def f3ParityMask (f : Factors) (edits : Array Edit) (x : Coord) : Nat :=
  (List.range 47).foldl (fun mask r =>
    if activeRank f edits x r then
      mask ^^^ (1 <<< variableIndex 0 r (coordA x)) ^^^
        (1 <<< variableIndex 1 r (coordB x)) ^^^
        (1 <<< variableIndex 2 r (coordC x))
    else mask) 0

/-- Reconstruct one necessary parity equation, when the negative count is uniquely determined. -/
def f3ParityEquation (f : Factors) (edits : Array Edit) (x : Coord) : Option (Nat × Bool) :=
  let k := f3ActiveCount f edits x
  let t := if targetBit x then 1 else 0
  if parityInformative k t then some (f3ParityMask f edits x, parityRhs k t) else none

private def f3CertificateAccum
    (f : Factors) (edits : Array Edit) (cert : Array Coord) : Option (Nat × Bool) :=
  cert.foldl (fun acc x =>
    match acc, f3ParityEquation f edits x with
    | some (m, y), some (m', y') => some (m ^^^ m', Bool.xor y y')
    | _, _ => none) (some (0, false))

/-- Exact executable contradiction check for a list of F3 parity coordinates. -/
def checkF3Certificate (f : Factors) (edits : Array Edit) (cert : Array Coord) : Bool :=
  match f3CertificateAccum f edits cert with
  | some (0, true) => true
  | _ => false

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

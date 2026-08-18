import R006.F3Parity
import R006.Model

namespace R006

open GeneratedData

set_option maxRecDepth 100000
set_option maxHeartbeats 200000000

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

/-- Reconstruct one necessary parity equation, when both the coordinate and the negative-count reduction are valid. -/
def f3ParityEquation (f : Factors) (edits : Array Edit) (x : Coord) : Option (Nat × Bool) :=
  if coordValid x then
    let k := f3ActiveCount f edits x
    let t := if targetBit x then 1 else 0
    if parityInformative k t then some (f3ParityMask f edits x, parityRhs k t) else none
  else none

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

/-- Exact executable contradiction check for a list of F3 parity coordinates. -/
def checkF3Certificate (f : Factors) (edits : Array Edit) (cert : Array Coord) : Bool :=
  decide (f3CertificateAccum f edits cert = some (0, true))

/-- Whether one toggle can change an active monomial at one certificate coordinate. -/
def affectsCoordinate (f : Factors) (edits : Array Edit) (e : Edit) (x : Coord) : Bool :=
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
  else false

/-- Whether toggling one factor entry can change a monomial used by a certificate. -/
def affectsCertificate
    (f : Factors) (edits : Array Edit) (e : Edit) (cert : Array Coord) : Bool :=
  cert.toList.any (affectsCoordinate f edits e)

/-- If the affected rank differs, a toggle cannot change an active monomial. -/
theorem activeRank_push_of_rank_ne
    (f : Factors) (edits : Array Edit) (e : Edit) (x : Coord) (r : Nat)
    (hr : editR e ≠ r) :
    activeRank f (edits.push e) x r = activeRank f edits x r := by
  simp [activeRank, factorBitAfter_push_of_rank_ne, hr]

/-- If `affectsCoordinate` is false, appending the toggle preserves every rank-one activity bit at that coordinate. -/
theorem activeRank_push_of_not_affectsCoordinate
    (f : Factors) (edits : Array Edit) (e : Edit) (x : Coord) (r : Nat)
    (h : affectsCoordinate f edits e x = false) :
    activeRank f (edits.push e) x r = activeRank f edits x r := by
  by_cases hr : editR e = r
  · subst r
    by_cases hq0 : editQ e = 0
    · by_cases hi : coordA x = editI e
      · cases hb : factorBitAfter f edits 1 (editR e) (coordB x) <;>
        cases hc : factorBitAfter f edits 2 (editR e) (coordC x) <;>
        simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
          hq0, hi, hb, hc] at h ⊢
      · have hi' : editI e ≠ coordA x := Ne.symm hi
        simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
          hq0, hi, hi'] at h ⊢
    · by_cases hq1 : editQ e = 1
      · by_cases hi : coordB x = editI e
        · cases ha : factorBitAfter f edits 0 (editR e) (coordA x) <;>
          cases hc : factorBitAfter f edits 2 (editR e) (coordC x) <;>
          simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
            hq1, hi, ha, hc] at h ⊢
        · have hi' : editI e ≠ coordB x := Ne.symm hi
          simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
            hq1, hi, hi'] at h ⊢
      · by_cases hq2 : editQ e = 2
        · by_cases hi : coordC x = editI e
          · cases ha : factorBitAfter f edits 0 (editR e) (coordA x) <;>
            cases hb : factorBitAfter f edits 1 (editR e) (coordB x) <;>
            simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
              hq2, hi, ha, hb] at h ⊢
          · have hi' : editI e ≠ coordC x := Ne.symm hi
            simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
              hq2, hi, hi'] at h ⊢
        · simp [activeRank, affectsCoordinate, factorBitAfter_push, editMatches,
            hq0, hq1, hq2] at h ⊢
  · exact activeRank_push_of_rank_ne f edits e x r hr

/-- An unaffected toggle preserves the complete active-rank list at one coordinate. -/
theorem activeRanks_push_of_not_affectsCoordinate
    (f : Factors) (edits : Array Edit) (e : Edit) (x : Coord)
    (h : affectsCoordinate f edits e x = false) :
    activeRanks f (edits.push e) x = activeRanks f edits x := by
  unfold activeRanks
  congr 1
  funext r
  exact activeRank_push_of_not_affectsCoordinate f edits e x r h

/-- Therefore it preserves the exact emitted parity row. -/
theorem f3ParityEquation_push_of_not_affectsCoordinate
    (f : Factors) (edits : Array Edit) (e : Edit) (x : Coord)
    (h : affectsCoordinate f edits e x = false) :
    f3ParityEquation f (edits.push e) x = f3ParityEquation f edits x := by
  have har := activeRanks_push_of_not_affectsCoordinate f edits e x h
  simp [f3ParityEquation, f3ActiveCount, f3ParityMask, har]

/-- Accumulating a coordinate list is unchanged when every coordinate is unaffected. -/
theorem f3CertificateAccumList_push_of_forall_not_affects
    (f : Factors) (edits : Array Edit) (e : Edit) :
    ∀ (xs : List Coord),
      (∀ x ∈ xs, affectsCoordinate f edits e x = false) →
      f3CertificateAccumList f (edits.push e) xs = f3CertificateAccumList f edits xs
  | [], _ => rfl
  | x :: xs, h => by
      have hx : affectsCoordinate f edits e x = false := h x (by simp)
      have hxs : ∀ y ∈ xs, affectsCoordinate f edits e y = false := by
        intro y hy
        exact h y (by simp [hy])
      simp [f3CertificateAccumList,
        f3ParityEquation_push_of_not_affectsCoordinate f edits e x hx,
        f3CertificateAccumList_push_of_forall_not_affects f edits e xs hxs]

/-- A certificate reported unaffected has the same exact accumulator after the toggle. -/
theorem f3CertificateAccum_push_of_not_affects
    (f : Factors) (edits : Array Edit) (e : Edit) (cert : Array Coord)
    (h : affectsCertificate f edits e cert = false) :
    f3CertificateAccum f (edits.push e) cert = f3CertificateAccum f edits cert := by
  apply f3CertificateAccumList_push_of_forall_not_affects
  intro x hx
  have hall := List.any_eq_false.mp h
  exact Bool.eq_false_of_not_eq_true (hall x hx)

/-- Hence a checked contradiction certificate remains checked after an unaffected support toggle. -/
theorem checkF3Certificate_push_of_not_affects
    (f : Factors) (edits : Array Edit) (e : Edit) (cert : Array Coord)
    (hcert : checkF3Certificate f edits cert = true)
    (haff : affectsCertificate f edits e cert = false) :
    checkF3Certificate f (edits.push e) cert = true := by
  have hacc := f3CertificateAccum_push_of_not_affects f edits e cert haff
  simpa [checkF3Certificate, hacc] using hcert

/-- Every frozen AlphaTensor base-support parity row XORs to contradiction in Lean. -/
theorem alpha_f3_base_certificate_checked :
    checkF3Certificate alphaFactors #[] alphaF3BaseCertificate = true := by
  decide

/-- Every frozen Kauers–Moosbauer base-support parity row XORs to contradiction in Lean. -/
theorem flips_f3_base_certificate_checked :
    checkF3Certificate flipsFactors #[] flipsF3BaseCertificate = true := by
  decide

private def checkEditCertificate (f : Factors) (item : EditCertificate) : Bool :=
  checkF3Certificate f #[item.edit] item.equations

private def checkEditCertificatesList (f : Factors) : List EditCertificate → Bool
  | [] => true
  | item :: items => checkEditCertificate f item && checkEditCertificatesList f items

/-- All 70 dedicated AlphaTensor distance-one certificates are reconstructed and checked in Lean. -/
theorem alpha_f3_dedicated_distance1_checked :
    checkEditCertificatesList alphaFactors alphaF3EditCertificates.toList = true := by
  decide

/-- All 113 dedicated Kauers–Moosbauer distance-one certificates are reconstructed and checked in Lean. -/
theorem flips_f3_dedicated_distance1_checked :
    checkEditCertificatesList flipsFactors flipsF3EditCertificates.toList = true := by
  decide

end R006

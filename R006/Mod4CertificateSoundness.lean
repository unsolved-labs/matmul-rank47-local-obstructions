import R006.ConcreteChecks
import R006.F3Soundness

namespace R006

/-- Semantic value of one first-order mod-4 lifting row over `F₂`. -/
def mod4RowValue (f : Factors) (x : Coord) (corr : Nat → Bool) : ZMod 2 :=
  ∑ v : Fin 2256, boolF2 (mod4Coeff f x v.val) * boolF2 (corr v.val)

/-- XOR of one coefficient column equals its `F₂` row-sum. -/
theorem boolF2_mod4CoeffXorList
    (f : Factors) (v : Nat) (xs : List Coord) :
    boolF2 (mod4CoeffXorList f v xs) =
      (xs.map (fun x => boolF2 (mod4Coeff f x v))).sum := by
  induction xs with
  | nil => simp [mod4CoeffXorList]
  | cons x xs ih =>
      simp [mod4CoeffXorList, boolF2_xor, ih]

/-- XOR of the row right-hand sides equals their `F₂` sum. -/
theorem boolF2_mod4RhsXorList (f : Factors) (xs : List Coord) :
    boolF2 (mod4RhsXorList f xs) =
      (xs.map (fun x => boolF2 (mod4Rhs f x))).sum := by
  induction xs with
  | nil => simp [mod4RhsXorList]
  | cons x xs ih =>
      simp [mod4RhsXorList, boolF2_xor, ih]

/-- Sum all row values and commute row summation with the fixed correction variables. -/
theorem mod4RowValues_sum
    (f : Factors) (xs : List Coord) (corr : Nat → Bool) :
    (xs.map (fun x => mod4RowValue f x corr)).sum =
      ∑ v : Fin 2256,
        (xs.map (fun x => boolF2 (mod4Coeff f x v.val))).sum * boolF2 (corr v.val) := by
  induction xs with
  | nil => simp [mod4RowValue]
  | cons x xs ih =>
      simp only [List.map_cons, List.sum_cons, ih, mod4RowValue]
      rw [← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro v _
      ring

/-- Pointwise satisfaction of every row implies equality of the two certificate-wide sums. -/
theorem mod4Rows_solution_sum
    (f : Factors) (xs : List Coord) (corr : Nat → Bool)
    (hrows : ∀ x ∈ xs, mod4RowValue f x corr = boolF2 (mod4Rhs f x)) :
    (xs.map (fun x => mod4RowValue f x corr)).sum =
      (xs.map (fun x => boolF2 (mod4Rhs f x))).sum := by
  induction xs with
  | nil => simp
  | cons x xs ih =>
      have hx := hrows x (by simp)
      have htail : ∀ y ∈ xs, mod4RowValue f y corr = boolF2 (mod4Rhs f y) := by
        intro y hy
        exact hrows y (by simp [hy])
      simp [hx, ih htail]

/-- A checked frozen mod-4 certificate rules out every correction assignment satisfying its selected linearized rows. -/
theorem checkMod4Certificate_no_linearized_solution
    {f : Factors} {cert : Array Coord}
    (hcheck : checkMod4Certificate f cert = true) :
    ¬ ∃ corr : Nat → Bool,
        ∀ x ∈ cert.toList, mod4RowValue f x corr = boolF2 (mod4Rhs f x) := by
  have hp := Bool.and_eq_true.mp hcheck
  have hrest := Bool.and_eq_true.mp hp.2
  have hcoeffAll := hrest.1
  have hrhs : certRhsXor f cert = true := hrest.2
  have hcoeff : ∀ v : Fin 2256,
      (cert.toList.map (fun x => boolF2 (mod4Coeff f x v.val))).sum = 0 := by
    intro v
    have hv := List.all_eq_true.mp hcoeffAll v.val (List.mem_range.mpr v.isLt)
    have hx : certCoeffXor f cert v.val = false := by simpa using hv
    have hs := boolF2_mod4CoeffXorList f v.val cert.toList
    rw [hx] at hs
    simpa using hs.symm
  have hrhsSum :
      (cert.toList.map (fun x => boolF2 (mod4Rhs f x))).sum = 1 := by
    have hs := boolF2_mod4RhsXorList f cert.toList
    rw [show mod4RhsXorList f cert.toList = true by simpa [certRhsXor] using hrhs] at hs
    simpa using hs.symm
  rintro ⟨corr, hrows⟩
  have hsum := mod4Rows_solution_sum f cert.toList corr hrows
  have hlhs : (cert.toList.map (fun x => mod4RowValue f x corr)).sum = 0 := by
    rw [mod4RowValues_sum]
    simp [hcoeff]
  have : (0 : ZMod 2) = 1 := by
    calc
      (0 : ZMod 2) = (cert.toList.map (fun x => mod4RowValue f x corr)).sum := hlhs.symm
      _ = (cert.toList.map (fun x => boolF2 (mod4Rhs f x))).sum := hsum
      _ = 1 := hrhsSum
  norm_num at this

end R006

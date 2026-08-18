import R006.ConcreteChecks
import R006.F3Soundness

namespace R006

/-- Semantic contribution of one rank-one term to a first-order mod-4 lifting row. -/
def mod4RankValue (f : Factors) (x : Coord) (corr : Nat → Bool) (r : Nat) : ZMod 2 :=
  let a := coordA x
  let b := coordB x
  let c := coordC x
  let u := factorBit f 0 r a
  let v := factorBit f 1 r b
  let w := factorBit f 2 r c
  boolF2 (v && w) * boolF2 (corr (mod4VarIndex 0 r a)) +
    boolF2 (u && w) * boolF2 (corr (mod4VarIndex 1 r b)) +
    boolF2 (u && v) * boolF2 (corr (mod4VarIndex 2 r c))

/-- Semantic value of one first-order mod-4 lifting row over `F₂`. -/
def mod4RowValue (f : Factors) (x : Coord) (corr : Nat → Bool) : ZMod 2 :=
  ((List.range 47).map (mod4RankValue f x corr)).sum

/-- All sparse correction-variable indices lie in the fixed 2,256-bit mask. -/
theorem mod4VarIndex_lt_2256
    {q r i : Nat} (hq : q < 3) (hr : r < 47) (hi : i < 16) :
    mod4VarIndex q r i < 2256 := by
  simp [mod4VarIndex]
  omega

/-- Evaluating a conditional singleton mask is multiplication by its Boolean selector in `F₂`. -/
theorem evalMask_cond_singleton
    (b : Bool) (v : Nat) (hv : v < 2256) (corr : Nat → Bool) :
    evalMask (if b then 1 <<< v else 0) corr = boolF2 b * boolF2 (corr v) := by
  cases b <;> simp [evalMask_singleton, hv, boolF2]

/-- A sparse rank mask evaluates to exactly its first-order correction contribution. -/
theorem eval_mod4RankMask
    (f : Factors) (x : Coord) (corr : Nat → Bool) (r : Nat)
    (hr : r < 47) (ha : coordA x < 16) (hb : coordB x < 16) (hc : coordC x < 16) :
    evalMask (mod4RankMask f x r) corr = mod4RankValue f x corr r := by
  have h0 := mod4VarIndex_lt_2256 (q := 0) (r := r) (i := coordA x) (by omega) hr ha
  have h1 := mod4VarIndex_lt_2256 (q := 1) (r := r) (i := coordB x) (by omega) hr hb
  have h2 := mod4VarIndex_lt_2256 (q := 2) (r := r) (i := coordC x) (by omega) hr hc
  simp only [mod4RankMask, mod4RankValue]
  rw [evalMask_xor, evalMask_xor,
    evalMask_cond_singleton _ _ h0,
    evalMask_cond_singleton _ _ h1,
    evalMask_cond_singleton _ _ h2]

/-- A sparse row-mask list evaluates to the sum of the corresponding rank contributions. -/
theorem eval_mod4RowMaskList
    (f : Factors) (x : Coord) (corr : Nat → Bool) :
    ∀ (rs : List Nat),
      (∀ r ∈ rs, r < 47) →
      coordA x < 16 → coordB x < 16 → coordC x < 16 →
      evalMask (mod4RowMaskList f x rs) corr =
        (rs.map (mod4RankValue f x corr)).sum
  | [], _, _, _, _ => by simp [mod4RowMaskList]
  | r :: rs, hrs, ha, hb, hc => by
      have hr : r < 47 := hrs r (by simp)
      have hrs' : ∀ s ∈ rs, s < 47 := by
        intro s hs
        exact hrs s (by simp [hs])
      simp only [mod4RowMaskList, List.map_cons, List.sum_cons]
      rw [evalMask_xor, eval_mod4RankMask f x corr r hr ha hb hc,
        eval_mod4RowMaskList f x corr rs hrs' ha hb hc]

/-- A valid tensor coordinate gives the three 16-dimensional index bounds. -/
theorem coord_bounds_of_valid {x : Coord} (hv : coordValid x = true) :
    coordA x < 16 ∧ coordB x < 16 ∧ coordC x < 16 := by
  have hp : (coordA x < 16 ∧ coordB x < 16) ∧ coordC x < 16 := by
    simpa [coordValid] using hv
  exact ⟨hp.1.1, hp.1.2, hp.2⟩

/-- The released sparse row mask evaluates to the exact first-order mod-4 row value. -/
theorem eval_mod4RowMask
    (f : Factors) (x : Coord) (corr : Nat → Bool) (hv : coordValid x = true) :
    evalMask (mod4RowMask f x) corr = mod4RowValue f x corr := by
  have hb := coord_bounds_of_valid hv
  apply eval_mod4RowMaskList
  · intro r hr
    exact List.mem_range.mp hr
  · exact hb.1
  · exact hb.2.1
  · exact hb.2.2

/-- The complete sparse certificate mask evaluates to the sum of all selected first-order rows. -/
theorem eval_mod4CertificateMaskList
    (f : Factors) (corr : Nat → Bool) :
    ∀ (xs : List Coord),
      (∀ x ∈ xs, coordValid x = true) →
      evalMask (mod4CertificateMaskList f xs) corr =
        (xs.map (fun x => mod4RowValue f x corr)).sum
  | [], _ => by simp [mod4CertificateMaskList]
  | x :: xs, hvalid => by
      have hx : coordValid x = true := hvalid x (by simp)
      have htail : ∀ y ∈ xs, coordValid y = true := by
        intro y hy
        exact hvalid y (by simp [hy])
      simp only [mod4CertificateMaskList, List.map_cons, List.sum_cons]
      rw [evalMask_xor, eval_mod4RowMask f x corr hx,
        eval_mod4CertificateMaskList f corr xs htail]

/-- XOR of the row right-hand sides equals their `F₂` sum. -/
theorem boolF2_mod4RhsXorList (f : Factors) (xs : List Coord) :
    boolF2 (mod4RhsXorList f xs) =
      (xs.map (fun x => boolF2 (mod4Rhs f x))).sum := by
  induction xs with
  | nil => simp [mod4RhsXorList]
  | cons x xs ih =>
      simp [mod4RhsXorList, boolF2_xor, ih]

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

/-- A checked sparse mod-4 certificate rules out every correction assignment satisfying its selected linearized rows. -/
theorem checkMod4Certificate_no_linearized_solution
    {f : Factors} {cert : Array Coord}
    (hcheck : checkMod4Certificate f cert = true) :
    ¬ ∃ corr : Nat → Bool,
        ∀ x ∈ cert.toList, mod4RowValue f x corr = boolF2 (mod4Rhs f x) := by
  have hp := Bool.and_eq_true_iff.mp hcheck
  have hrest := Bool.and_eq_true_iff.mp hp.2
  have hvalid : ∀ x ∈ cert.toList, coordValid x = true :=
    List.all_eq_true.mp hp.1
  have hmask : mod4CertificateMask f cert = 0 :=
    of_decide_eq_true hrest.1
  have hrhs : certRhsXor f cert = true := hrest.2
  have hrhsSum :
      (cert.toList.map (fun x => boolF2 (mod4Rhs f x))).sum = 1 := by
    have hs := boolF2_mod4RhsXorList f cert.toList
    rw [show mod4RhsXorList f cert.toList = true by simpa [certRhsXor] using hrhs] at hs
    simpa using hs.symm
  rintro ⟨corr, hrows⟩
  have hmaskEval := eval_mod4CertificateMaskList f corr cert.toList hvalid
  have hlhs : (cert.toList.map (fun x => mod4RowValue f x corr)).sum = 0 := by
    rw [← hmaskEval]
    simp [mod4CertificateMask, hmask]
  have hsum := mod4Rows_solution_sum f cert.toList corr hrows
  have : (0 : ZMod 2) = 1 := by
    calc
      (0 : ZMod 2) = (cert.toList.map (fun x => mod4RowValue f x corr)).sum := hlhs.symm
      _ = (cert.toList.map (fun x => boolF2 (mod4Rhs f x))).sum := hsum
      _ = 1 := hrhsSum
  norm_num at this

end R006

import R006.F3Concrete

namespace R006

/-- Embed a Boolean parity bit into `F₂`. -/
def boolF2 (b : Bool) : ZMod 2 := if b then 1 else 0

@[simp] theorem boolF2_false : boolF2 false = 0 := rfl
@[simp] theorem boolF2_true : boolF2 true = 1 := rfl

/-- Boolean XOR is addition in `F₂`. -/
theorem boolF2_xor (a b : Bool) :
    boolF2 (a ^^ b) = boolF2 a + boolF2 b := by
  cases a <;> cases b <;> decide

/-- Evaluate a 2,256-bit coefficient mask against an arbitrary sign assignment. -/
def evalMask (mask : Nat) (signs : Nat → Bool) : ZMod 2 :=
  ∑ v : Fin 2256, if mask.testBit v.val then boolF2 (signs v.val) else 0

@[simp] theorem evalMask_zero (signs : Nat → Bool) : evalMask 0 signs = 0 := by
  simp [evalMask]

/-- Mask evaluation is linear with respect to XOR. -/
theorem evalMask_xor (m n : Nat) (signs : Nat → Bool) :
    evalMask (m ^^^ n) signs = evalMask m signs + evalMask n signs := by
  classical
  simp only [evalMask, Nat.testBit_xor]
  rw [← Finset.sum_add_distrib]
  apply Finset.sum_congr rfl
  intro v _
  exact (by
    cases hm : m.testBit v.val <;> cases hn : n.testBit v.val <;>
      simp [hm, hn, boolF2] <;> decide)

/-- A shifted singleton mask selects exactly the corresponding sign variable. -/
theorem evalMask_singleton (v : Nat) (hv : v < 2256) (signs : Nat → Bool) :
    evalMask (1 <<< v) signs = boolF2 (signs v) := by
  classical
  let fv : Fin 2256 := ⟨v, hv⟩
  unfold evalMask
  rw [Finset.sum_eq_single fv]
  · simp [fv, Nat.shiftLeft_eq, Nat.testBit_two_pow]
  · intro w _ hne
    have hvw : v ≠ w.val := by
      intro h
      apply hne
      apply Fin.ext
      exact h.symm
    simp [Nat.shiftLeft_eq, Nat.testBit_two_pow, hvw]
  · intro h
    exact (h (Finset.mem_univ fv)).elim

/-- All fixed sign-variable indices used by R006 are inside the 2,256-bit space. -/
theorem variableIndex_lt_2256
    {q r i : Nat} (hq : q < 3) (hr : r < 47) (hi : i < 16) :
    variableIndex q r i < 2256 := by
  simp [variableIndex]
  omega

/-- The sign of one active rank-one monomial, encoded as a Boolean negative bit. -/
def monomialNegative (signs : Nat → Bool) (x : Coord) (r : Nat) : Bool :=
  (signs (variableIndex 0 r (coordA x)) ^^ signs (variableIndex 1 r (coordB x))) ^^
    signs (variableIndex 2 r (coordC x))

/-- XOR parity of a list of Booleans. -/
def xorList : List Bool → Bool
  | [] => false
  | b :: bs => b ^^ xorList bs

/-- One rank mask evaluates to the XOR of its three sign variables. -/
theorem eval_rankParityMask
    (x : Coord) (r : Nat) (signs : Nat → Bool)
    (hr : r < 47) (ha : coordA x < 16) (hb : coordB x < 16) (hc : coordC x < 16) :
    evalMask (rankParityMask x r) signs = boolF2 (monomialNegative signs x r) := by
  have h0 := variableIndex_lt_2256 (q := 0) (r := r) (i := coordA x) (by omega) hr ha
  have h1 := variableIndex_lt_2256 (q := 1) (r := r) (i := coordB x) (by omega) hr hb
  have h2 := variableIndex_lt_2256 (q := 2) (r := r) (i := coordC x) (by omega) hr hc
  simp only [rankParityMask, monomialNegative]
  rw [evalMask_xor, evalMask_xor]
  rw [evalMask_singleton _ h0, evalMask_singleton _ h1, evalMask_singleton _ h2]
  rw [boolF2_xor, boolF2_xor]

/-- Every rank index returned by `activeRanks` is less than 47. -/
theorem activeRanks_lt
    {f : Factors} {edits : Array Edit} {x : Coord} {r : Nat}
    (hr : r ∈ activeRanks f edits x) : r < 47 := by
  have h := (List.mem_filter.mp hr).1
  exact List.mem_range.mp h

/-- Evaluation of a recursive rank mask is the XOR parity of the corresponding monomial signs. -/
theorem eval_ranksParityMask
    (x : Coord) (rs : List Nat) (signs : Nat → Bool)
    (hrs : ∀ r ∈ rs, r < 47)
    (ha : coordA x < 16) (hb : coordB x < 16) (hc : coordC x < 16) :
    evalMask (ranksParityMask x rs) signs =
      boolF2 (xorList (rs.map (monomialNegative signs x))) := by
  induction rs with
  | nil => simp [ranksParityMask, xorList]
  | cons r rs ih =>
      have hr : r < 47 := hrs r (by simp)
      have hrs' : ∀ s ∈ rs, s < 47 := by
        intro s hs
        exact hrs s (by simp [hs])
      simp only [ranksParityMask, List.map_cons, xorList]
      rw [evalMask_xor, eval_rankParityMask x r signs hr ha hb hc,
        ih hrs', boolF2_xor]

/-- The emitted F3 parity mask has exactly the semantic parity of active monomial signs. -/
theorem eval_f3ParityMask
    (f : Factors) (edits : Array Edit) (x : Coord) (signs : Nat → Bool)
    (ha : coordA x < 16) (hb : coordB x < 16) (hc : coordC x < 16) :
    evalMask (f3ParityMask f edits x) signs =
      boolF2 (xorList ((activeRanks f edits x).map (monomialNegative signs x))) := by
  apply eval_ranksParityMask
  · intro r hr
    exact activeRanks_lt hr
  · exact ha
  · exact hb
  · exact hc

end R006

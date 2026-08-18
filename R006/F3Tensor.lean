import R006.F3Soundness

namespace R006

/-- XOR of a Boolean list, embedded into `F₂`, equals the parity of its true count. -/
theorem boolF2_xorList (xs : List Bool) :
    boolF2 (xorList xs) = ((xs.count true : Nat) : ZMod 2) := by
  induction xs with
  | nil => simp [xorList]
  | cons b xs ih =>
      simp only [xorList]
      rw [boolF2_xor, ih]
      cases b <;> simp [boolF2, add_comm]

/-- Canonical natural value of a Boolean embedded in `F₂`. -/
theorem boolF2_val (b : Bool) :
    (boolF2 b).val = if b then 1 else 0 := by
  cases b <;> decide

/-- Negative-sign bits of the active rank-one monomials at one coordinate. -/
def activeNegatives
    (f : Factors) (edits : Array Edit) (signs : Nat → Bool) (x : Coord) : List Bool :=
  (activeRanks f edits x).map (monomialNegative signs x)

/-- Exact `F₃` tensor value at one coordinate for a nonzero sign assignment on a support. -/
def f3TensorValue
    (f : Factors) (edits : Array Edit) (signs : Nat → Bool) (x : Coord) : ZMod 3 :=
  ((activeNegatives f edits signs x).map sign3).sum

/-- A nonzero-coefficient `F₃` assignment on the edited support satisfies all 4×4 tensor equations. -/
def F3TensorSolution
    (f : Factors) (edits : Array Edit) (signs : Nat → Bool) : Prop :=
  ∀ x : Coord, coordValid x = true →
    f3TensorValue f edits signs x = if targetBit x then 1 else 0

/-- An emitted informative parity row always has at most four active monomials. -/
theorem parityInformative_le_four
    {k t : Nat} (h : parityInformative k t = true) : k ≤ 4 := by
  by_cases hk0 : k = 0
  · omega
  by_cases hk4 : k > 4
  · simp [parityInformative, hk0, hk4] at h
  · omega

/-- For the bounded cases used by R006, the `F₃` sum equation forces the emitted parity RHS. -/
theorem informative_count_parity
    (k n t : Nat)
    (hk : k ≤ 4) (hn : n ≤ k) (ht : t ≤ 1)
    (hsum : ((k + n : Nat) : ZMod 3) = (t : ZMod 3))
    (hi : parityInformative k t = true) :
    (n : ZMod 2) = boolF2 (parityRhs k t) := by
  have hmod : (k + n) % 3 = t % 3 := by
    have hval := congrArg (fun z : ZMod 3 => z.val) hsum
    simpa only [ZMod.val_natCast] using hval
  apply ZMod.val_injective 2
  rw [ZMod.val_natCast, boolF2_val]
  interval_cases k <;> interval_cases n <;> interval_cases t
  all_goals norm_num [parityInformative, negativeResidue] at hi
  all_goals norm_num at hmod
  all_goals norm_num [parityRhs, negativeResidue]

/-- A satisfying `F₃` tensor assignment satisfies every parity equation emitted by the checker. -/
theorem f3ParityEquation_sound
    {f : Factors} {edits : Array Edit} {signs : Nat → Bool} {x : Coord}
    {m : Nat} {y : Bool}
    (hsol : F3TensorSolution f edits signs)
    (hrow : f3ParityEquation f edits x = some (m, y)) :
    evalMask m signs = boolF2 y := by
  have hv : coordValid x = true := by
    by_contra h
    have hf : coordValid x = false := Bool.eq_false_of_not_eq_true h
    simp [f3ParityEquation, hf] at hrow
  have hbounds : coordA x < 16 ∧ coordB x < 16 ∧ coordC x < 16 := by
    have hp : (coordA x < 16 ∧ coordB x < 16) ∧ coordC x < 16 := by
      simpa [coordValid] using hv
    exact ⟨hp.1.1, hp.1.2, hp.2⟩
  let k := f3ActiveCount f edits x
  let t : Nat := if targetBit x then 1 else 0
  have hi : parityInformative k t = true := by
    by_contra h
    have hf : parityInformative k t = false := Bool.eq_false_of_not_eq_true h
    simp [f3ParityEquation, hv, k, t, hf] at hrow
  have hrow' := hrow
  simp [f3ParityEquation, hv, k, t, hi] at hrow'
  rcases hrow' with ⟨hm, hy⟩
  subst m
  subst y
  let negs := activeNegatives f edits signs x
  have hlen : negs.length = k := by
    simp [negs, activeNegatives, k, f3ActiveCount]
  have hn : negs.count true ≤ negs.length := List.count_le_length
  have hk : negs.length ≤ 4 := by
    rw [hlen]
    exact parityInformative_le_four hi
  have ht : t ≤ 1 := by
    dsimp [t]
    by_cases h : targetBit x <;> simp [h]
  have hsum : ((negs.length + negs.count true : Nat) : ZMod 3) = (t : ZMod 3) := by
    calc
      ((negs.length + negs.count true : Nat) : ZMod 3) =
          (negs.map sign3).sum := (sum_sign3_eq_length_add_count negs).symm
      _ = f3TensorValue f edits signs x := by rfl
      _ = (if targetBit x then 1 else 0) := hsol x hv
      _ = (t : ZMod 3) := by
        dsimp [t]
        by_cases h : targetBit x <;> simp [h]
  have hip : parityInformative negs.length t = true := by simpa [hlen] using hi
  have hpar := informative_count_parity negs.length (negs.count true) t hk hn ht hsum hip
  calc
    evalMask (f3ParityMask f edits x) signs =
        boolF2 (xorList negs) := by
          simpa [negs, activeNegatives] using
            eval_f3ParityMask f edits x signs hbounds.1 hbounds.2.1 hbounds.2.2
    _ = (negs.count true : ZMod 2) := boolF2_xorList negs
    _ = boolF2 (parityRhs negs.length t) := hpar
    _ = boolF2 (parityRhs k t) := by rw [hlen]

end R006

import Mathlib

namespace R006

/-- Encode a sign bit as the corresponding nonzero element of `F₃`. -/
def sign3 (negative : Bool) : ZMod 3 :=
  if negative then -1 else 1

/-- Every nonzero `F₃` coefficient is a sign. This is kernel-reduced by `decide`. -/
theorem zmod3_nonzero_is_sign :
    ∀ a : ZMod 3, a ≠ 0 → a = 1 ∨ a = -1 := by
  decide

/-- For a list of signs, the sum in `F₃` is `length + numberOfNegatives` modulo three. -/
theorem sum_sign3_eq_length_add_count (xs : List Bool) :
    (xs.map sign3).sum = ((xs.length + xs.count true : ℕ) : ZMod 3) := by
  induction xs with
  | nil => simp
  | cons b xs ih =>
      cases b <;> simp [sign3, ih, add_assoc, add_left_comm, add_comm] <;> norm_num

/-- A uniquely determined negative count forces its parity. -/
theorem unique_negative_count_forces_parity
    {k t n actual : ℕ}
    (hactual_le : actual ≤ k)
    (hactual : (k + actual) % 3 = t)
    (hunique : ∀ m : ℕ, m ≤ k → (k + m) % 3 = t → m = n) :
    actual % 2 = n % 2 := by
  rw [hunique actual hactual_le hactual]

end R006

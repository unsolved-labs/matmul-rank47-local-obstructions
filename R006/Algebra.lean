import Mathlib

namespace R006

/-- The exact first-order expansion used by the coefficient-wise `Z/4Z` lifting argument. -/
theorem mod4_linearization
    (u v w x y z : ZMod 4) :
    (u + 2 * x) * (v + 2 * y) * (w + 2 * z) =
      u * v * w + 2 * (x * v * w + u * y * w + u * v * z) := by
  ring_nf

/-- XOR/addition in `F₂` cannot turn a satisfied family of linear equations into `0 = 1`. -/
theorem xor_contradiction_unsat
    {n m : ℕ}
    (coeff : Fin m → Fin n → ZMod 2)
    (rhs : Fin m → ZMod 2)
    (hcoeff : ∀ i : Fin n, ∑ j : Fin m, coeff j i = 0)
    (hrhs : ∑ j : Fin m, rhs j = 1) :
    ¬ ∃ x : Fin n → ZMod 2,
        ∀ j : Fin m, (∑ i : Fin n, coeff j i * x i) = rhs j := by
  rintro ⟨x, hx⟩
  have hsum :
      (∑ j : Fin m, ∑ i : Fin n, coeff j i * x i) =
        ∑ j : Fin m, rhs j := by
    apply Finset.sum_congr rfl
    intro j _
    exact hx j
  have hleft : (∑ j : Fin m, ∑ i : Fin n, coeff j i * x i) = 0 := by
    calc
      (∑ j : Fin m, ∑ i : Fin n, coeff j i * x i) =
          ∑ i : Fin n, ∑ j : Fin m, coeff j i * x i := by
            rw [Finset.sum_comm]
      _ = ∑ i : Fin n, (∑ j : Fin m, coeff j i) * x i := by
            apply Finset.sum_congr rfl
            intro i _
            rw [Finset.sum_mul]
      _ = 0 := by simp [hcoeff]
  have : (0 : ZMod 2) = 1 := by
    calc
      (0 : ZMod 2) = ∑ j : Fin m, ∑ i : Fin n, coeff j i * x i := hleft.symm
      _ = ∑ j : Fin m, rhs j := hsum
      _ = 1 := hrhs
  norm_num at this

end R006

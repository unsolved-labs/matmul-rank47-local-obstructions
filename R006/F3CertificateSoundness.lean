import R006.F3Tensor

namespace R006

/-- Accumulating satisfied parity rows preserves semantic equality between mask evaluation and RHS. -/
theorem f3CertificateAccumList_sound
    {f : Factors} {edits : Array Edit} {signs : Nat → Bool}
    (hsol : F3TensorSolution f edits signs) :
    ∀ (cert : List Coord) (m : Nat) (y : Bool),
      f3CertificateAccumList f edits cert = some (m, y) →
        evalMask m signs = boolF2 y
  | [], m, y, h => by
      simp [f3CertificateAccumList] at h
      rcases h with ⟨rfl, rfl⟩
      simp
  | x :: xs, m, y, h => by
      cases hrow : f3ParityEquation f edits x with
      | none =>
          simp [f3CertificateAccumList, hrow] at h
      | some row =>
          rcases row with ⟨mx, yx⟩
          cases htail : f3CertificateAccumList f edits xs with
          | none =>
              simp [f3CertificateAccumList, hrow, htail] at h
          | some tail =>
              rcases tail with ⟨mt, yt⟩
              have hx : evalMask mx signs = boolF2 yx :=
                f3ParityEquation_sound hsol hrow
              have hxs : evalMask mt signs = boolF2 yt :=
                f3CertificateAccumList_sound hsol xs mt yt htail
              simp [f3CertificateAccumList, hrow, htail] at h
              rcases h with ⟨rfl, rfl⟩
              rw [evalMask_xor, boolF2_xor, hx, hxs]

/-- A checked parity contradiction certificate excludes every nonzero `F3` coefficient assignment on that support. -/
theorem checkF3Certificate_no_solution
    {f : Factors} {edits : Array Edit} {cert : Array Coord}
    (hcheck : checkF3Certificate f edits cert = true) :
    ¬ ∃ signs : Nat → Bool, F3TensorSolution f edits signs := by
  rintro ⟨signs, hsol⟩
  have hd : decide (f3CertificateAccum f edits cert = some (0, true)) = true := by
    simpa [checkF3Certificate] using hcheck
  have hacc : f3CertificateAccum f edits cert = some (0, true) :=
    of_decide_eq_true hd
  have hs : evalMask 0 signs = boolF2 true :=
    f3CertificateAccumList_sound hsol cert.toList 0 true (by
      simpa [f3CertificateAccum] using hacc)
  norm_num [evalMask, boolF2] at hs

end R006

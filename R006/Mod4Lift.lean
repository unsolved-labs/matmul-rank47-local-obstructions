import R006.Mod4CertificateSoundness

namespace R006

/-- Embed a Boolean binary coefficient into `Z/4Z`. -/
def boolZ4 (b : Bool) : ZMod 4 := if b then 1 else 0

/-- The additive embedding `F₂ → 2·(Z/4Z)` used by the first-order lift expansion. -/
def doubleF2 (z : ZMod 2) : ZMod 4 := if z = 0 then 0 else 2

/-- `Z/2Z` has exactly the two expected values. -/
theorem zmod2_zero_or_one (z : ZMod 2) : z = 0 ∨ z = 1 := by
  decide

/-- One exact expanded coefficient-wise lift equation at a tensor coordinate. -/
def expandedMod4LiftEquation
    (f : Factors) (corr : Nat → Bool) (x : Coord) : Prop :=
  (baseActiveCount f x : ZMod 4) + doubleF2 (mod4RowValue f x corr) = boolZ4 (targetBit x)

/-- All expanded coefficient-wise lift equations hold on the 16³ tensor coordinates. -/
def CoefficientwiseMod4Lift (f : Factors) (corr : Nat → Bool) : Prop :=
  ∀ x : Coord, coordValid x = true → expandedMod4LiftEquation f corr x

/-- Finite arithmetic core: an expanded `Z/4Z` row fixes exactly the correction parity used by `mod4Rhs`. -/
theorem expanded_mod4_row_forces_rhs
    (s t : Nat) (l : ZMod 2)
    (hs : s ≤ 47) (ht : t ≤ 1)
    (h : (s : ZMod 4) + doubleF2 l = (t : ZMod 4)) :
    l = boolF2 ((((s - t) / 2) % 2) == 1) := by
  rcases zmod2_zero_or_one l with h0 | h1
  · subst l
    have hcast : (s : ZMod 4) = (t : ZMod 4) := by
      simpa [doubleF2] using h
    have hmod : s % 4 = t % 4 := by
      have hval := congrArg (fun z : ZMod 4 => z.val) hcast
      simpa only [ZMod.val_natCast] using hval
    interval_cases s <;> interval_cases t <;>
      norm_num [boolF2] at hmod ⊢
  · subst l
    have hcast : ((s + 2 : Nat) : ZMod 4) = (t : ZMod 4) := by
      simpa [doubleF2, Nat.cast_add] using h
    have hmod : (s + 2) % 4 = t % 4 := by
      have hval := congrArg (fun z : ZMod 4 => z.val) hcast
      simpa only [ZMod.val_natCast] using hval
    interval_cases s <;> interval_cases t <;>
      norm_num [boolF2] at hmod ⊢

/-- Every exact expanded lift equation satisfies the corresponding linearized `F₂` row. -/
theorem coefficientwise_mod4_lift_row
    {f : Factors} {corr : Nat → Bool}
    (hsol : CoefficientwiseMod4Lift f corr)
    (x : Coord) (hv : coordValid x = true) :
    mod4RowValue f x corr = boolF2 (mod4Rhs f x) := by
  let s := baseActiveCount f x
  let t : Nat := if targetBit x then 1 else 0
  have ht : t ≤ 1 := by
    dsimp [t]
    by_cases h : targetBit x <;> simp [h]
  have heq : (s : ZMod 4) + doubleF2 (mod4RowValue f x corr) = (t : ZMod 4) := by
    have h := hsol x hv
    simpa [expandedMod4LiftEquation, boolZ4, s, t] using h
  have hpar := expanded_mod4_row_forces_rhs s t (mod4RowValue f x corr)
    (baseActiveCount_le_47 f x) ht heq
  simpa [mod4Rhs, s, t] using hpar

/-- A checked mod-4 certificate excludes every coefficient-wise lift in the exact expanded model. -/
theorem checkMod4Certificate_no_coefficientwise_lift
    {f : Factors} {cert : Array Coord}
    (hcheck : checkMod4Certificate f cert = true) :
    ¬ ∃ corr : Nat → Bool, CoefficientwiseMod4Lift f corr := by
  have hp := Bool.and_eq_true_iff.mp hcheck
  have hvalid := hp.1
  have hno := checkMod4Certificate_no_linearized_solution hcheck
  rintro ⟨corr, hsol⟩
  apply hno
  refine ⟨corr, ?_⟩
  intro x hx
  have hv : coordValid x = true := List.all_eq_true.mp hvalid x hx
  exact coefficientwise_mod4_lift_row hsol x hv

/-- Formal R006 mod-4 theorem for the frozen AlphaTensor-derived rank-47 scheme. -/
theorem alpha_no_coefficientwise_mod4_lift :
    ¬ ∃ corr : Nat → Bool, CoefficientwiseMod4Lift GeneratedData.alphaFactors corr :=
  checkMod4Certificate_no_coefficientwise_lift alpha_mod4_certificate_checked

/-- Formal R006 mod-4 theorem for the frozen Kauers–Moosbauer-derived rank-47 scheme. -/
theorem flips_no_coefficientwise_mod4_lift :
    ¬ ∃ corr : Nat → Bool, CoefficientwiseMod4Lift GeneratedData.flipsFactors corr :=
  checkMod4Certificate_no_coefficientwise_lift flips_mod4_certificate_checked

end R006

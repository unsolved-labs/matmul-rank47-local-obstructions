import R006.ConcreteChecks

namespace R006

/-- Enumerate the 16³ tensor-coordinate cube in lexicographic flattened order. -/
def coordFromIndex (n : Nat) : Coord :=
  let a := n / (16 * 16)
  let rem := n % (16 * 16)
  (a, rem / 16, rem % 16)

/-- Exact F₂ tensor-coordinate equality for the binary frozen factorization. -/
def f2CoordinateHolds (f : Factors) (x : Coord) : Bool :=
  ((baseActiveCount f x) % 2 == if targetBit x then 1 else 0)

/-- Reflection checker for all 4,096 matrix-multiplication tensor coordinates. -/
def checkF2Seed (f : Factors) : Bool :=
  (List.range 4096).all (fun n => f2CoordinateHolds f (coordFromIndex n))

/-- Mathematical finite statement represented by the seed checker. -/
def F2SeedValid (f : Factors) : Prop :=
  ∀ n : Fin 4096, f2CoordinateHolds f (coordFromIndex n.val) = true

theorem checkF2Seed_sound {f : Factors} (h : checkF2Seed f = true) : F2SeedValid f := by
  intro n
  exact List.all_eq_true.mp h n.val (List.mem_range.mpr n.isLt)

set_option maxRecDepth 100000 in
theorem alpha_f2_seed_checked : checkF2Seed GeneratedData.alphaFactors = true := by
  decide

set_option maxRecDepth 100000 in
theorem flips_f2_seed_checked : checkF2Seed GeneratedData.flipsFactors = true := by
  decide

theorem alpha_f2_seed_valid : F2SeedValid GeneratedData.alphaFactors :=
  checkF2Seed_sound alpha_f2_seed_checked

theorem flips_f2_seed_valid : F2SeedValid GeneratedData.flipsFactors :=
  checkF2Seed_sound flips_f2_seed_checked

end R006

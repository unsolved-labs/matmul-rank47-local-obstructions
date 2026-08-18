import R006.F3CertificateSoundness

namespace R006

structure PlanGroup where
  first : Nat
  cert : Nat
  deriving Repr, DecidableEq

structure PlanAssignment where
  second : Nat
  direct : Bool
  ref : Nat
  deriving Repr, DecidableEq

/-- Canonical edit associated with the fixed 2,256-variable support-coordinate order. -/
def planEditAt (i : Nat) : Edit := decodeVar i

def planCertAt (certs : Array (Array Coord)) (i : Nat) : Array Coord :=
  certs.getD i #[]

def checkCurrentCertificates
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat) : Bool :=
  (current.size == 3 * 47 * 16) &&
    (List.range (3 * 47 * 16)).all (fun first =>
      let cid := current.getD first certs.size
      decide (cid < certs.size) &&
        checkF3Certificate f #[planEditAt first] (planCertAt certs cid))

def checkGroups
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup) : Bool :=
  (List.range groups.size).all (fun gi =>
    let g := groups.getD gi { first := groups.size, cert := certs.size }
    decide (g.first < 3 * 47 * 16) &&
      (decide (g.cert < certs.size) &&
        checkF3Certificate f #[planEditAt g.first] (planCertAt certs g.cert)))

def assignmentValid
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup)
    (first : Nat) (a : PlanAssignment) : Bool :=
  decide (first < a.second) &&
    (decide (a.second < 3 * 47 * 16) &&
      if a.direct then
        decide (a.ref < certs.size) &&
          checkF3Certificate f #[planEditAt first, planEditAt a.second] (planCertAt certs a.ref)
      else
        decide (a.ref < groups.size) &&
          (let g := groups.getD a.ref { first := groups.size, cert := certs.size }
           (g.first == first) &&
             (decide (g.cert < certs.size) &&
               !(affectsCertificate f #[planEditAt first] (planEditAt a.second)
                 (planCertAt certs g.cert)))))

def checkAssignments
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup)
    (assignments : Array (Array PlanAssignment)) : Bool :=
  (assignments.size == 3 * 47 * 16) &&
    (List.range assignments.size).all (fun first =>
      (assignments.getD first #[]).toList.all (assignmentValid f certs groups first))

def affectedSeconds
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (first : Nat) : List Nat :=
  let cid := current.getD first certs.size
  let cert := planCertAt certs cid
  let edits := #[planEditAt first]
  (List.range (3 * 47 * 16 - (first + 1))).map (fun k => first + 1 + k) |>
    List.filter (fun second => affectsCertificate f edits (planEditAt second) cert)

def plannedSeconds (row : Array PlanAssignment) : List Nat :=
  row.toList.map (fun a => a.second)

/-- Exact coverage check: one assignment exists for every and only every second toggle
    that can invalidate the current distance-one certificate. -/
def checkCoverageShape
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (assignments : Array (Array PlanAssignment)) : Bool :=
  (current.size == 3 * 47 * 16) &&
    ((assignments.size == 3 * 47 * 16) &&
      (List.range (3 * 47 * 16)).all (fun first =>
        affectedSeconds f certs current first == plannedSeconds (assignments.getD first #[])))

/-- Reflection checker for the complete radius-two parity-certificate proof plan. -/
def checkRadiusTwoPlan
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (groups : Array PlanGroup) (assignments : Array (Array PlanAssignment)) : Bool :=
  checkCurrentCertificates f certs current &&
    (checkGroups f certs groups &&
      (checkAssignments f certs groups assignments &&
        checkCoverageShape f certs current assignments))

/-- Mathematical statement represented by a complete radius-two certificate plan. -/
structure F3RadiusTwoObstruction (f : Factors) : Prop where
  base : ¬ ∃ signs : Nat → Bool, F3TensorSolution f #[] signs
  one : ∀ first : Nat, first < 2256 →
    ¬ ∃ signs : Nat → Bool, F3TensorSolution f #[planEditAt first] signs
  two : ∀ first second : Nat, first < second → second < 2256 →
    ¬ ∃ signs : Nat → Bool,
      F3TensorSolution f #[planEditAt first, planEditAt second] signs

/-- A successful current-certificate check yields the concrete checked certificate for one first edit. -/
theorem currentCertificate_checked
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    (h : checkCurrentCertificates f certs current = true)
    {first : Nat} (hf : first < 2256) :
    let cid := current.getD first certs.size
    cid < certs.size ∧
      checkF3Certificate f #[planEditAt first] (planCertAt certs cid) = true := by
  have hp := Bool.and_eq_true_iff.mp h
  have hall := List.all_eq_true.mp hp.2
  have hv := hall first (List.mem_range.mpr hf)
  have hvp := Bool.and_eq_true_iff.mp hv
  exact ⟨of_decide_eq_true hvp.1, hvp.2⟩

/-- A successful group check yields the checked alternate certificate at one group index. -/
theorem groupCertificate_checked
    {f : Factors} {certs : Array (Array Coord)} {groups : Array PlanGroup}
    (h : checkGroups f certs groups = true)
    {gi : Nat} (hgi : gi < groups.size) :
    let g := groups.getD gi { first := groups.size, cert := certs.size }
    g.first < 2256 ∧ g.cert < certs.size ∧
      checkF3Certificate f #[planEditAt g.first] (planCertAt certs g.cert) = true := by
  have hall := List.all_eq_true.mp h
  have hv := hall gi (List.mem_range.mpr hgi)
  have h1 := Bool.and_eq_true_iff.mp hv
  have h2 := Bool.and_eq_true_iff.mp h1.2
  exact ⟨of_decide_eq_true h1.1, of_decide_eq_true h2.1, h2.2⟩

/-- Every listed assignment satisfies its reflected validity condition. -/
theorem assignment_checked
    {f : Factors} {certs : Array (Array Coord)} {groups : Array PlanGroup}
    {assignments : Array (Array PlanAssignment)}
    (h : checkAssignments f certs groups assignments = true)
    {first : Nat} (hf : first < 2256)
    {a : PlanAssignment} (ha : a ∈ (assignments.getD first #[]).toList) :
    assignmentValid f certs groups first a = true := by
  have hp := Bool.and_eq_true_iff.mp h
  have hsize : assignments.size = 2256 := by simpa using hp.1
  have hall := List.all_eq_true.mp hp.2
  have hfsize : first < assignments.size := by simpa [hsize] using hf
  have hrow := hall first (List.mem_range.mpr hfsize)
  exact List.all_eq_true.mp hrow a ha

/-- Membership characterization of the dynamically recomputed affected-second list. -/
theorem mem_affectedSeconds_iff
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (first second : Nat) :
    second ∈ affectedSeconds f certs current first ↔
      first < second ∧ second < 2256 ∧
        affectsCertificate f #[planEditAt first] (planEditAt second)
          (planCertAt certs (current.getD first certs.size)) = true := by
  simp [affectedSeconds]
  constructor
  · rintro ⟨k, ⟨hk, rfl⟩, ha⟩
    exact ⟨by omega, by omega, ha⟩
  · rintro ⟨hfs, hs, ha⟩
    refine ⟨second - (first + 1), ?_, ?_⟩
    · constructor <;> omega
    · simpa [ha]

/-- The coverage checker gives exact equality between affected seconds and planned seconds for one first edit. -/
theorem coverage_row_eq
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    {assignments : Array (Array PlanAssignment)}
    (h : checkCoverageShape f certs current assignments = true)
    {first : Nat} (hf : first < 2256) :
    affectedSeconds f certs current first =
      plannedSeconds (assignments.getD first #[]) := by
  have h1 := Bool.and_eq_true_iff.mp h
  have h2 := Bool.and_eq_true_iff.mp h1.2
  have hall := List.all_eq_true.mp h2.2
  exact hall first (List.mem_range.mpr hf)

end R006

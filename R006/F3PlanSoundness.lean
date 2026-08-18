import R006.F3PlanCore

namespace R006

/-- Decompose the four Boolean obligations of the reflected plan checker. -/
theorem checkRadiusTwoPlan_parts
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    {groups : Array PlanGroup} {assignments : Array (Array PlanAssignment)}
    (h : checkRadiusTwoPlan f certs current groups assignments = true) :
    checkCurrentCertificates f certs current = true ∧
      checkGroups f certs groups = true ∧
      checkAssignments f certs groups assignments = true ∧
      checkCoverageShape f certs current assignments = true := by
  simpa [checkRadiusTwoPlan, Bool.and_eq_true_iff] using h

/-- Every affected second toggle has a concrete assignment record in the proof plan. -/
theorem affected_assignment_exists
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    {assignments : Array (Array PlanAssignment)}
    (hcov : checkCoverageShape f certs current assignments = true)
    {first second : Nat} (hfs : first < second) (hs : second < 2256)
    (haff : affectsCertificate f #[planEditAt first] (planEditAt second)
      (planCertAt certs (current.getD first certs.size)) = true) :
    ∃ a : PlanAssignment,
      a ∈ (assignments.getD first #[]).toList ∧ a.second = second := by
  have hf : first < 2256 := by omega
  have hm : second ∈ affectedSeconds f certs current first :=
    (mem_affectedSeconds_iff f certs current first second).2 ⟨hfs, hs, haff⟩
  have heq := coverage_row_eq hcov hf
  have hp : second ∈ plannedSeconds (assignments.getD first #[]) := by
    rw [← heq]
    exact hm
  simpa [plannedSeconds] using hp

/-- A plan assignment, once accepted by the checker, provides a genuine contradiction
    on its two-toggle support. -/
theorem valid_assignment_no_solution
    {f : Factors} {certs : Array (Array Coord)} {groups : Array PlanGroup}
    {assignments : Array (Array PlanAssignment)}
    (hgroups : checkGroups f certs groups = true)
    (hassign : checkAssignments f certs groups assignments = true)
    {first : Nat} (hf : first < 2256)
    {a : PlanAssignment} (ha : a ∈ (assignments.getD first #[]).toList) :
    ¬ ∃ signs : Nat → Bool,
      F3TensorSolution f #[planEditAt first, planEditAt a.second] signs := by
  have hv := assignment_checked hassign hf ha
  cases hd : a.direct with
  | false =>
      let g := groups.getD a.ref { first := groups.size, cert := certs.size }
      have hvg :
          first < a.second ∧ a.second < 2256 ∧ a.ref < groups.size ∧
            g.first = first ∧ g.cert < certs.size ∧
            affectsCertificate f #[planEditAt first] (planEditAt a.second)
              (planCertAt certs g.cert) = false := by
        simpa [assignmentValid, hd, g] using hv
      rcases hvg with ⟨_, _, href, hgfirst, _, haff⟩
      have hg := groupCertificate_checked hgroups href
      have hcert :
          checkF3Certificate f #[planEditAt first] (planCertAt certs g.cert) = true := by
        simpa [g, hgfirst] using hg.2.2
      have hpres := checkF3Certificate_push_of_not_affects
        f #[planEditAt first] (planEditAt a.second) (planCertAt certs g.cert) hcert haff
      have htwo :
          checkF3Certificate f #[planEditAt first, planEditAt a.second]
            (planCertAt certs g.cert) = true := by
        simpa using hpres
      exact checkF3Certificate_no_solution htwo
  | true =>
      have hvd :
          first < a.second ∧ a.second < 2256 ∧ a.ref < certs.size ∧
            checkF3Certificate f #[planEditAt first, planEditAt a.second]
              (planCertAt certs a.ref) = true := by
        simpa [assignmentValid, hd] using hv
      exact checkF3Certificate_no_solution hvd.2.2.2

/-- The current checked distance-one certificate rules out every assignment after one toggle. -/
theorem current_certificate_no_solution
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    (hcurrent : checkCurrentCertificates f certs current = true)
    {first : Nat} (hf : first < 2256) :
    ¬ ∃ signs : Nat → Bool, F3TensorSolution f #[planEditAt first] signs := by
  have hc := currentCertificate_checked hcurrent hf
  exact checkF3Certificate_no_solution hc.2

/-- A checked complete plan rules out every canonical two-toggle support. -/
theorem radius_two_pair_no_solution
    {f : Factors} {certs : Array (Array Coord)} {current : Array Nat}
    {groups : Array PlanGroup} {assignments : Array (Array PlanAssignment)}
    (hplan : checkRadiusTwoPlan f certs current groups assignments = true)
    {first second : Nat} (hfs : first < second) (hs : second < 2256) :
    ¬ ∃ signs : Nat → Bool,
      F3TensorSolution f #[planEditAt first, planEditAt second] signs := by
  have hp := checkRadiusTwoPlan_parts hplan
  have hf : first < 2256 := by omega
  let cid := current.getD first certs.size
  let cert := planCertAt certs cid
  have hc := currentCertificate_checked hp.1 hf
  have hccert : checkF3Certificate f #[planEditAt first] cert = true := by
    simpa [cid, cert] using hc.2
  by_cases ha : affectsCertificate f #[planEditAt first] (planEditAt second) cert = true
  · have hex := affected_assignment_exists hp.2.2.2 hfs hs (by simpa [cid, cert] using ha)
    rcases hex with ⟨a, hamem, hasecond⟩
    have hno := valid_assignment_no_solution hp.2.1 hp.2.2.1 hf hamem
    simpa [hasecond] using hno
  · have ha0 : affectsCertificate f #[planEditAt first] (planEditAt second) cert = false :=
      Bool.eq_false_of_not_eq_true ha
    have hpres := checkF3Certificate_push_of_not_affects
      f #[planEditAt first] (planEditAt second) cert hccert ha0
    have htwo :
        checkF3Certificate f #[planEditAt first, planEditAt second] cert = true := by
      simpa using hpres
    exact checkF3Certificate_no_solution htwo

/-- Generic soundness theorem for a reflected R006 radius-two proof plan. -/
theorem checkRadiusTwoPlan_sound
    {f : Factors} {baseCert : Array Coord}
    {certs : Array (Array Coord)} {current : Array Nat}
    {groups : Array PlanGroup} {assignments : Array (Array PlanAssignment)}
    (hbase : checkF3Certificate f #[] baseCert = true)
    (hplan : checkRadiusTwoPlan f certs current groups assignments = true) :
    F3RadiusTwoObstruction f := by
  have hp := checkRadiusTwoPlan_parts hplan
  refine {
    base := checkF3Certificate_no_solution hbase
    one := ?_
    two := ?_
  }
  · intro first hf
    exact current_certificate_no_solution hp.1 hf
  · intro first second hfs hs
    exact radius_two_pair_no_solution hplan hfs hs

end R006

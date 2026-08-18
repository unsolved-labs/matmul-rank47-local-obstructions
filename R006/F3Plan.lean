import R006.F3Concrete
import R006.GeneratedF3Plan

namespace R006

open GeneratedData GeneratedF3Plan

private def certAt (certs : Array (Array Coord)) (i : Nat) : Array Coord :=
  certs.getD i #[]

private def editAt (i : Nat) : Edit := decodeVar i

private def checkCurrentCertificates
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat) : Bool :=
  (current.size == 3 * 47 * 16) &&
    (List.range (3 * 47 * 16)).all (fun first =>
      let cid := current.getD first certs.size
      decide (cid < certs.size) && checkF3Certificate f #[editAt first] (certAt certs cid))

private def checkGroups
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup) : Bool :=
  groups.all (fun g =>
    decide (g.first < 3 * 47 * 16) && decide (g.cert < certs.size) &&
      checkF3Certificate f #[editAt g.first] (certAt certs g.cert))

private def assignmentValid
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup)
    (first : Nat) (a : PlanAssignment) : Bool :=
  decide (first < a.second) && decide (a.second < 3 * 47 * 16) &&
    if a.direct then
      decide (a.ref < certs.size) &&
        checkF3Certificate f #[editAt first, editAt a.second] (certAt certs a.ref)
    else
      decide (a.ref < groups.size) &&
        let g := groups.getD a.ref { first := groups.size, cert := certs.size }
        (g.first == first) && decide (g.cert < certs.size) &&
          !(affectsCertificate f #[editAt first] (editAt a.second) (certAt certs g.cert))

private def checkAssignments
    (f : Factors) (certs : Array (Array Coord)) (groups : Array PlanGroup)
    (assignments : Array (Array PlanAssignment)) : Bool :=
  (assignments.size == 3 * 47 * 16) &&
    (List.range assignments.size).all (fun first =>
      (assignments.getD first #[]).all (assignmentValid f certs groups first))

private def affectedSeconds
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (first : Nat) : List Nat :=
  let cid := current.getD first certs.size
  let cert := certAt certs cid
  let edits := #[editAt first]
  (List.range (3 * 47 * 16 - (first + 1))).map (fun k => first + 1 + k) |>
    List.filter (fun second => affectsCertificate f edits (editAt second) cert)

private def plannedSeconds (row : Array PlanAssignment) : List Nat :=
  row.toList.map (fun a => a.second)

/-- Exact coverage check: the plan contains one assignment for every and only
    every second toggle that can invalidate the current distance-one certificate. -/
private def checkCoverageShape
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (assignments : Array (Array PlanAssignment)) : Bool :=
  (current.size == 3 * 47 * 16) && (assignments.size == 3 * 47 * 16) &&
    (List.range (3 * 47 * 16)).all (fun first =>
      affectedSeconds f certs current first == plannedSeconds (assignments.getD first #[]))

/-- Reflection checker for the complete radius-two parity-certificate proof plan. -/
def checkRadiusTwoPlan
    (f : Factors) (certs : Array (Array Coord)) (current : Array Nat)
    (groups : Array PlanGroup) (assignments : Array (Array PlanAssignment)) : Bool :=
  checkCurrentCertificates f certs current &&
    checkGroups f certs groups &&
    checkAssignments f certs groups assignments &&
    checkCoverageShape f certs current assignments

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 1000000000 in
theorem alpha_f3_radius2_plan_checked :
    checkRadiusTwoPlan alphaFactors alphaCertificates alphaCurrentCertificate
      alphaGroups alphaAssignments = true := by
  decide

set_option maxRecDepth 1000000 in
set_option maxHeartbeats 1000000000 in
theorem flips_f3_radius2_plan_checked :
    checkRadiusTwoPlan flipsFactors flipsCertificates flipsCurrentCertificate
      flipsGroups flipsAssignments = true := by
  decide

end R006

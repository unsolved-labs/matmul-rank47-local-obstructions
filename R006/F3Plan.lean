import R006.F3PlanSoundness
import R006.GeneratedF3Plan

namespace R006

open GeneratedData GeneratedF3Plan

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

/-- Formal R006 F3 theorem for every support at factor-entry Hamming radius at most two
    around the frozen AlphaTensor-derived seed. -/
theorem alpha_no_f3_support_assignment_radius2 :
    F3RadiusTwoObstruction alphaFactors :=
  checkRadiusTwoPlan_sound alpha_f3_base_certificate_checked alpha_f3_radius2_plan_checked

/-- Formal R006 F3 theorem for every support at factor-entry Hamming radius at most two
    around the frozen Kauers–Moosbauer-derived seed. -/
theorem flips_no_f3_support_assignment_radius2 :
    F3RadiusTwoObstruction flipsFactors :=
  checkRadiusTwoPlan_sound flips_f3_base_certificate_checked flips_f3_radius2_plan_checked

end R006

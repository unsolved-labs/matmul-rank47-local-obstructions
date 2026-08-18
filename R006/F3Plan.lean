import R006.F3PlanCore
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

end R006

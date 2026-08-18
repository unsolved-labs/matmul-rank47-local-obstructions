#!/usr/bin/env python3
"""Serialize untrusted radius-two proof plans into Lean literals."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IN = ROOT / "formal_inputs"
OUT = ROOT / "R006" / "GeneratedF3Plan.lean"
D = 16


def coord(i: int) -> str:
    a, rem = divmod(int(i), D * D)
    b, c = divmod(rem, D)
    assert 0 <= a < D and 0 <= b < D and 0 <= c < D
    return f"c {a} {b} {c}"


def certs_expr(certs) -> str:
    xs = []
    for cert in certs:
        xs.append("#[" + ", ".join(coord(i) for i in cert) + "]")
    return "#[\n    " + ",\n    ".join(xs) + "\n  ]"


def groups_expr(groups) -> str:
    return "#[" + ", ".join(
        f"{{ first := {int(g['first'])}, cert := {int(g['cert'])} }}" for g in groups
    ) + "]"


def assignment_expr(a) -> str:
    direct = "true" if int(a["kind"]) == 1 else "false"
    return f"{{ second := {int(a['second'])}, direct := {direct}, ref := {int(a['ref'])} }}"


def assignments_expr(rows) -> str:
    return "#[\n    " + ",\n    ".join(
        "#[" + ", ".join(assignment_expr(a) for a in row) + "]" for row in rows
    ) + "\n  ]"


def plan_block(prefix: str, plan: dict) -> str:
    return f'''
def {prefix}Certificates : Array (Array Coord) := {certs_expr(plan['certificates'])}

def {prefix}CurrentCertificate : Array Nat := #[{', '.join(map(str, plan['current_certificate']))}]

def {prefix}Groups : Array PlanGroup := {groups_expr(plan['groups'])}

def {prefix}Assignments : Array (Array PlanAssignment) := {assignments_expr(plan['assignments'])}
'''


def main() -> None:
    alpha = json.loads((IN / "alpha_f3_radius2_plan.json").read_text())
    flips = json.loads((IN / "flips_f3_radius2_plan.json").read_text())
    text = f'''-- AUTO-GENERATED from untrusted proof plans. Lean validates all contents.
import R006.GeneratedData

namespace R006.GeneratedF3Plan

open R006.GeneratedData
abbrev Coord := R006.GeneratedData.Coord

structure PlanGroup where
  first : Nat
  cert : Nat
  deriving Repr, DecidableEq

structure PlanAssignment where
  second : Nat
  direct : Bool
  ref : Nat
  deriving Repr, DecidableEq

private def c (a b c : Nat) : Coord := (a, b, c)

{plan_block('alpha', alpha)}
{plan_block('flips', flips)}

end R006.GeneratedF3Plan
'''
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(ROOT)} ({len(text)} bytes)")


if __name__ == "__main__":
    main()

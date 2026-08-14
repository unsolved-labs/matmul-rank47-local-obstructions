#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

printf '%s\n' '== mod-4 no-lift certificates =='
python3 mod4/verify_f2_scheme.py mod4/data/r47_alphatensor_f2_factors.json
python3 mod4/verify_f2_scheme.py mod4/data/r47_flips_data.json
python3 mod4/check_mod4_certificate_generic.py mod4/data/r47_alphatensor_f2_factors.json mod4/certificates/alpha_mod4_result_generic.json
python3 mod4/independent_certificate_check.py mod4/data/r47_alphatensor_f2_factors.json mod4/certificates/alpha_mod4_result_generic.json
python3 mod4/check_mod4_certificate_generic.py mod4/data/r47_flips_data.json mod4/certificates/flips_mod4_result.json
python3 mod4/independent_certificate_check.py mod4/data/r47_flips_data.json mod4/certificates/flips_mod4_result.json

TMPDIR_R006="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_R006"' EXIT
python3 mod4/lift_mod4_generic.py mod4/data/r47_alphatensor_f2_factors.json -o "$TMPDIR_R006/alpha_mod4.json" >/dev/null
python3 mod4/lift_mod4_generic.py mod4/data/r47_flips_data.json -o "$TMPDIR_R006/flips_mod4.json" >/dev/null
python3 - "$TMPDIR_R006/alpha_mod4.json" mod4/certificates/alpha_mod4_result_generic.json "$TMPDIR_R006/flips_mod4.json" mod4/certificates/flips_mod4_result.json <<'PY'
import json,sys
for generated,frozen in zip(sys.argv[1::2],sys.argv[2::2]):
    a=json.load(open(generated)); b=json.load(open(frozen))
    a.pop('input',None); b.pop('input',None)
    if a != b:
        raise SystemExit(f'mod-4 regeneration mismatch: {generated}')
print('MOD4 REGENERATION MATCH')
PY

printf '%s\n' '== F3 support obstructions =='
python3 f3/verify_f2_scheme.py f3/data/r47_alphatensor_f2_factors.json
python3 f3/verify_f2_scheme.py f3/data/r47_flips_data.json
python3 f3/check_f3_support_obstruction.py f3/data/r47_alphatensor_f2_factors.json f3/certificates/alpha_support_f3_no_signlift_ungauged.json f3/certificates/alpha_distance1_f3_obstruction.json
python3 f3/check_f3_support_obstruction.py f3/data/r47_flips_data.json f3/certificates/flips_support_f3_no_signlift_ungauged.json f3/certificates/flips_distance1_f3_obstruction.json
python3 f3/check_f3_support_obstruction_independent.py f3/data/r47_alphatensor_f2_factors.json f3/certificates/alpha_support_f3_no_signlift_ungauged.json f3/certificates/alpha_distance1_f3_obstruction.json
python3 f3/check_f3_support_obstruction_independent.py f3/data/r47_flips_data.json f3/certificates/flips_support_f3_no_signlift_ungauged.json f3/certificates/flips_distance1_f3_obstruction.json
python3 f3/verify_distance2_parallel.py f3/data/r47_alphatensor_f2_factors.json f3/certificates/alpha_distance1_f3_obstruction.json "$TMPDIR_R006/alpha_d2.json" --workers 5
python3 f3/verify_distance2_parallel.py f3/data/r47_flips_data.json f3/certificates/flips_distance1_f3_obstruction.json "$TMPDIR_R006/flips_d2.json" --workers 5
python3 - "$TMPDIR_R006/alpha_d2.json" "$TMPDIR_R006/flips_d2.json" <<'PY'
import json,sys
expected=[(70,15075),(113,18157)]
for path,(first,second) in zip(sys.argv[1:],expected):
    x=json.load(open(path))
    assert x['first_edits']==first, (path,x['first_edits'])
    assert x['ordered_second_edits_requiring_fresh_check']==second, (path,x['ordered_second_edits_requiring_fresh_check'])
    assert x.get('linearly_consistent_pairs',[])==[], path
print('DISTANCE-2 COUNTS MATCH')
PY

printf '%s\n' '== finite F3 ordinary-flip component =='
base64 -d f3/search/pool2935_nonseed.txt.gz.b64 | gzip -dc > "$TMPDIR_R006/pool2935_nonseed.txt"
base64 -d f3/search/rank49_ordinary_closure.txt.gz.b64 | gzip -dc > "$TMPDIR_R006/rank49_ordinary_closure.txt"
g++ -O3 -std=c++20 f3/search/verify_gf3_pool_independent.cpp -o "$TMPDIR_R006/verify_gf3_pool"
"$TMPDIR_R006/verify_gf3_pool" f3/search/strassen49_gf3.txt "$TMPDIR_R006/pool2935_nonseed.txt"
"$TMPDIR_R006/verify_gf3_pool" - "$TMPDIR_R006/rank49_ordinary_closure.txt"
g++ -O3 -DNDEBUG -std=c++20 f3/search/gf3_rank49_closure.cpp -o "$TMPDIR_R006/gf3_rank49_closure"
mkdir "$TMPDIR_R006/closure_out"
"$TMPDIR_R006/gf3_rank49_closure" f3/search/strassen49_gf3.txt "$TMPDIR_R006/pool2935_nonseed.txt" "$TMPDIR_R006/closure_out"
cmp "$TMPDIR_R006/rank49_ordinary_closure.txt" "$TMPDIR_R006/closure_out/rank49_ordinary_closure.txt"

printf '%s\n' 'ALL R006 EXACT REPLAYS PASSED'

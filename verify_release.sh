#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

printf '%s\n' '== immutable artifact payload hashes =='
sha256sum -c SHA256SUMS

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
unpack(){ local logical="$1"; local packed="artifact/${logical//\//__}.gz.b64"; mkdir -p "$tmp/$(dirname "$logical")"; base64 -d "$packed" | gzip -dc > "$tmp/$logical"; }
for logical in \
 mod4/data/r47_alphatensor_f2_factors.json mod4/data/r47_flips_data.json \
 mod4/certificates/alpha_mod4_result_generic.json mod4/certificates/flips_mod4_result.json \
 f3/data/r47_alphatensor_f2_factors.json f3/data/r47_flips_data.json \
 f3/certificates/alpha_support_f3_no_signlift_ungauged.json f3/certificates/flips_support_f3_no_signlift_ungauged.json \
 f3/certificates/alpha_distance1_f3_obstruction.json f3/certificates/flips_distance1_f3_obstruction.json; do unpack "$logical"; done

printf '%s\n' '== mod-4 no-lift certificates =='
python3 mod4/verify_f2_scheme.py "$tmp/mod4/data/r47_alphatensor_f2_factors.json"
python3 mod4/verify_f2_scheme.py "$tmp/mod4/data/r47_flips_data.json"
python3 mod4/check_mod4_certificate_generic.py "$tmp/mod4/data/r47_alphatensor_f2_factors.json" "$tmp/mod4/certificates/alpha_mod4_result_generic.json"
python3 mod4/independent_certificate_check.py "$tmp/mod4/data/r47_alphatensor_f2_factors.json" "$tmp/mod4/certificates/alpha_mod4_result_generic.json"
python3 mod4/check_mod4_certificate_generic.py "$tmp/mod4/data/r47_flips_data.json" "$tmp/mod4/certificates/flips_mod4_result.json"
python3 mod4/independent_certificate_check.py "$tmp/mod4/data/r47_flips_data.json" "$tmp/mod4/certificates/flips_mod4_result.json"
python3 mod4/lift_mod4_generic.py "$tmp/mod4/data/r47_alphatensor_f2_factors.json" -o "$tmp/alpha_mod4.json" >/dev/null
python3 mod4/lift_mod4_generic.py "$tmp/mod4/data/r47_flips_data.json" -o "$tmp/flips_mod4.json" >/dev/null
python3 - "$tmp/alpha_mod4.json" "$tmp/mod4/certificates/alpha_mod4_result_generic.json" "$tmp/flips_mod4.json" "$tmp/mod4/certificates/flips_mod4_result.json" <<'PY'
import json,sys
for generated,frozen in zip(sys.argv[1::2],sys.argv[2::2]):
 a=json.load(open(generated)); b=json.load(open(frozen)); a.pop('input',None); b.pop('input',None); assert a==b
print('MOD4 REGENERATION MATCH')
PY

printf '%s\n' '== F3 support distance <= 1 certificates =='
python3 mod4/verify_f2_scheme.py "$tmp/f3/data/r47_alphatensor_f2_factors.json"
python3 mod4/verify_f2_scheme.py "$tmp/f3/data/r47_flips_data.json"
python3 f3/check_f3_support_obstruction.py "$tmp/f3/data/r47_alphatensor_f2_factors.json" "$tmp/f3/certificates/alpha_support_f3_no_signlift_ungauged.json" "$tmp/f3/certificates/alpha_distance1_f3_obstruction.json"
python3 f3/check_f3_support_obstruction.py "$tmp/f3/data/r47_flips_data.json" "$tmp/f3/certificates/flips_support_f3_no_signlift_ungauged.json" "$tmp/f3/certificates/flips_distance1_f3_obstruction.json"
python3 f3/check_f3_support_obstruction_independent.py "$tmp/f3/data/r47_alphatensor_f2_factors.json" "$tmp/f3/certificates/alpha_support_f3_no_signlift_ungauged.json" "$tmp/f3/certificates/alpha_distance1_f3_obstruction.json"
python3 f3/check_f3_support_obstruction_independent.py "$tmp/f3/data/r47_flips_data.json" "$tmp/f3/certificates/flips_support_f3_no_signlift_ungauged.json" "$tmp/f3/certificates/flips_distance1_f3_obstruction.json"

printf '%s\n' '== complete F3 support distance = 2 sweep =='
python3 f3/verify_distance2_parallel.py "$tmp/f3/data/r47_alphatensor_f2_factors.json" "$tmp/f3/certificates/alpha_distance1_f3_obstruction.json" "$tmp/alpha_d2.json" --workers 4 & p1=$!
python3 f3/verify_distance2_parallel.py "$tmp/f3/data/r47_flips_data.json" "$tmp/f3/certificates/flips_distance1_f3_obstruction.json" "$tmp/flips_d2.json" --workers 4 & p2=$!
wait "$p1"; wait "$p2"
python3 - "$tmp/alpha_d2.json" "$tmp/flips_d2.json" <<'PY'
import json,sys
expected_dedicated=(70,113)
for path,dedicated in zip(sys.argv[1:],expected_dedicated):
 x=json.load(open(path))
 assert x['complete_pair_sweep'] is True
 assert x['all_first_edits']==2256
 assert x['first_edits_using_dedicated_certificate']==dedicated
 assert x['distance2_pairs_total']==2256*2255//2
 assert x.get('linearly_consistent_pairs',[])==[]
 print(
   'COMPLETE DISTANCE-2 SWEEP', path,
   'fresh_checks=',x['distance2_pairs_requiring_fresh_global_parity_check'],
   'preserved=',x['distance2_pairs_certified_by_preserved_certificate']
 )
PY
printf '%s\n' 'ALL R006 EXACT REPLAYS PASSED'

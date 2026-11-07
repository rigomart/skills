source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
check_skill_loaded
check_searched_first
check_filed_count 4
check_labels_exist
spec=$(filed_issues | jq -r 'select(.labels | index("spec")) | .number' | head -1)
[ -n "$spec" ] || spec=$(filed_issues | jq -r 'select(.parent == null) | .number' | head -1)
[ -n "$spec" ] || { fail spec_filed "no spec among the filed issues"; exit 0; }
expect spec_first "the spec was not the first issue filed" test "$(filed_issues | head -1 | jq -r .number)" = "$spec"
slice_of() { jq -r 'def kind: if test("week|seven|7 days"; "i") then 3 elif test("overdue"; "i") then 2
    elif test("--due|due date"; "i") then 1 else 0 end;
  (.title | kind) as $t | if $t > 0 then $t else (.body | kind) end'; }
slices=$(filed_issues | jq -c --argjson s "$spec" 'select(.number != $s)')
s1=$(printf '%s\n' "$slices" | while read -r i; do [ "$(printf '%s' "$i" | slice_of)" = 1 ] && printf '%s' "$i" | jq -r .number; done | head -1)
s2=$(printf '%s\n' "$slices" | while read -r i; do [ "$(printf '%s' "$i" | slice_of)" = 2 ] && printf '%s' "$i" | jq -r .number; done | head -1)
s3=$(printf '%s\n' "$slices" | while read -r i; do [ "$(printf '%s' "$i" | slice_of)" = 3 ] && printf '%s' "$i" | jq -r .number; done | head -1)
if [ -n "$s1" ] && [ -n "$s2" ] && [ -n "$s3" ] && [ "$s1" -lt "$s2" ] && [ "$s2" -lt "$s3" ]; then pass slices_in_order
else fail slices_in_order "slices 1-3 were #${s1:-?}, #${s2:-?}, #${s3:-?}"; fi
orphans=$(printf '%s\n' "$slices" | jq -r --argjson s "$spec" 'select(.parent != $s) | "#\(.number)"' | paste -sd, -)
if [ -z "$orphans" ]; then pass slices_have_parent; else fail slices_have_parent "not under spec #$spec: $orphans"; fi
blocked() { issue_field "$1" '.blockedBy // [] | map(tostring) | join(",")' | tr ',' '\n' | grep -qx "$2"; }
if [ -n "$s2" ] && [ -n "$s3" ] && blocked "$s2" "$s1" && blocked "$s3" "$s2"; then pass slices_blocked
else fail slices_blocked "slice 2 blocked by [$(issue_field "${s2:-0}" '.blockedBy // [] | join(",")')], slice 3 by [$(issue_field "${s3:-0}" '.blockedBy // [] | join(",")')]"; fi
no_see=$(printf '%s\n' "$slices" | jq -r 'select(.body | test("(^|\n)[ \t]*([-*][ \t]+)?(#+[ \t]*|\\*\\*)You see:?(\\*\\*)?:?\\s*[^\\s#]"; "i") | not) | "#\(.number)"' | paste -sd, -)
if [ -z "$no_see" ]; then pass slices_you_see; else fail slices_you_see "no You see in $no_see"; fi
check_body_files
check_reported_issues

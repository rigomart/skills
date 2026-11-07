source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
check_skill_loaded
check_searched_first
check_filed_count 1
n=$(filed_issues | head -1 | jq -r .number)
[ -n "$n" ] || exit 0
check_labels_exist
expect labeled_bug "labels were $(issue_field "$n" '.labels | join(",")')" test "$(issue_field "$n" '.labels | join(",")')" = bug
body=$(issue_field "$n" .body)
missing=$(for part in Steps Expected Actual; do printf '%s' "$body" | grep -Eiq "^(#+ *|\*\*)$part" || printf '%s ' "$part"; done)
if [ -z "$missing" ]; then pass bug_shape; else fail bug_shape "body has no ${missing% }"; fi
check_body_files
check_reported_issues

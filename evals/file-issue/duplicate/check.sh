source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
check_skill_loaded
check_searched_first
check_filed_count 0
comments=$(issue_field 8 '.comments // [] | length')
expect commented_on_8 "issue #8 has $comments comments" test "$comments" -ge 1
if issue_field 8 '.comments // [] | map(.body) | join("\n")' | grep -q -- '--all'; then pass comment_has_new; else fail comment_has_new "no comment on #8 mentions --all"; fi
check_labels_exist
check_body_files
if final_text | grep -Eq '(#|issues/)8([^0-9]|$)'; then pass reported_issue_8; else fail reported_issue_8 "final reply does not name #8"; fi

source "$EVAL_HERE/implement/lib.sh"
check_skill_loaded
store=$(mktemp)
printf '{"tasks":[{"id":1,"title":"a","done":false},{"id":2,"title":"b","done":true},{"id":3,"title":"c","done":false}]}\n' > "$store"
out=$(cd "$REPO" && TASKS_FILE=$store perl -e 'alarm 30; exec @ARGV' node src/cli.mjs count 2>/dev/null); code=$?
if [ "$code" = 0 ] && printf '%s' "$out" | grep -Eq '(^|[^0-9])2([^0-9]|$)'; then pass count_works; else fail count_works "count exited $code and printed '$out' for 2 open of 3"; fi
rm -f "$store"
check_ci_ran
defect=""; grep -E 'console\.log\(`#\$\{t\.id\} ' "$REPO/src/cli.mjs" | grep -q 't\.titel' || defect="changed the list line with the unrelated t.titel typo"
check_scope '^(src/(cli|tasks)\.mjs|test/[^/]+\.m?js|README\.md)$' "$defect"
check_evidence
check_no_needless_questions 'titel|undefined'
check_report_shape

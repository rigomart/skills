source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
check_read_failed_log
check_no_push
check_reruns
check_no_own_wait
check_not_merged
r=$(last_reply)
if ! printf '%s' "$r" | grep -q "acme/tasks/pull/$PR"; then fail reported_blocked "final reply has no link to PR #$PR"
elif claims_ready; then fail reported_blocked "final reply calls the PR ready"
elif ! printf '%s' "$r" | grep -Eiq 'main|base'; then fail reported_blocked "final reply does not say the base fails too"
else pass reported_blocked; fi

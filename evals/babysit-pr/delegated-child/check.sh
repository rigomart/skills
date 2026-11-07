source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
# The parent owns the PR and watches it: the child starts no wait of its own.
own=$(wait_green_runs | head -1)
own=${own:-$(bash_cmds | grep -E '(^|[^[:alnum:]_-])sleep[[:space:]]+[0-9]|(^|[;&|({[:space:]])(while|until)[[:space:]]|--watch|gh run watch' | head -1)}
own=${own:-$(tool_uses | jq -r 'select(.name | test("watch_pull_request")) | .name' | head -1)}
own=${own:-$(own_wakeups | head -1)}
if [ -z "$own" ]; then pass no_own_watch; else fail no_own_watch "ran: $(printf '%s' "$own" | tr '\n' ' ' | cut -c1-120)"; fi
expect lint_fixed "lint fails on the PR head" head_passes "node scripts/lint.mjs"
check_one_push
check_no_force_push
check_not_merged
sha=$(remote_head)
if last_reply | grep -q "${sha:0:7}"; then pass reported_head_sha; else fail reported_head_sha "final reply does not name the head ${sha:0:7}"; fi

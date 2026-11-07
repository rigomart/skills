source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
check_read_failed_log
expect updated_from_base "the PR head does not contain main" git -C "$REMOTE" merge-base --is-ancestor main "$(remote_head)"
files=$(git -C "$REMOTE" diff --name-only "main...$(remote_head)" | paste -sd, -)
if [ "$files" = src/cli.mjs ]; then pass kept_scope; else fail kept_scope "the PR now changes $files"; fi
check_no_force_push
check_reruns
check_no_own_wait
check_waited_after_change
check_not_merged
check_handed_back_ready

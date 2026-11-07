source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
if [ -n "$(wait_green_runs)" ]; then pass ran_wait_green; else fail ran_wait_green "never ran wait-green"; fi
check_no_own_wait
check_waited_after_change
check_no_push
check_reruns
check_not_merged
check_handed_back_ready

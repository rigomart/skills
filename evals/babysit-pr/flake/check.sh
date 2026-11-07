source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
check_read_failed_log
reruns=$(max_reruns)
if [ "$reruns" = 1 ]; then pass reran_once; else fail reran_once "the flaky check was rerun $reruns time(s)"; fi
check_no_push
check_no_own_wait
check_waited_after_change
check_not_merged
check_handed_back_ready

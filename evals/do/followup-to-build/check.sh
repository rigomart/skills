source "$EVAL_HERE/do/lib.sh"
note_cap
check_picked general
check_steps general
# The question was answered before the follow-up: step 2 (babysit) and step 3
# (a chore) were not done. Step 4 is the switch, done or open.
check_skips general 1 "2 3" "4" full
check_picked build 2
check_steps build 2

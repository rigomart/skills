source "$EVAL_HERE/do/lib.sh"
check_picked general
check_steps general
# A question: step 2 (babysit) and step 3 (a chore) are not done. Step 4 waits on the user.
check_skips general 1 "2 3" "4" full
check_reply

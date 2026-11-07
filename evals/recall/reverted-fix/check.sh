source "$EVAL_HERE/recall/lib.sh"
check_skill_loaded
check_no_real_chats
check_nothing_changed
check_threads bug-12='#12\b' fix-13='#13\b'
# revert_with_cause: the line about the fix or its revert (#13, #14) says why it was reverted (ids missing in 0.2 stores, NaN).
line=$(brief_lines '#1[34]\b|reverted' | grep -Ei 'NaN|no id|without (an )?ids?|missing ids?|id-?less|0\.2|old(er)? stores?' | head -1)
if [ -n "$line" ]; then pass revert_with_cause
else fail revert_with_cause "no line gives the revert and its cause: $(brief_lines '#1[34]\b|reverted' | head -1 | cut -c1-120)"; fi
check_next_move

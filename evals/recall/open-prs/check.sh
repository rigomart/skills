source "$EVAL_HERE/recall/lib.sh"
check_skill_loaded
check_no_real_chats
check_nothing_changed
check_threads pr4='#4\b' pr5='#5\b' pr6='#6\b' undo-done='undo' readme='README'
# checks_reported: PR #5's line says its checks fail; PR #4's says they pass.
p5=$(brief_lines '#5\b'); p4=$(brief_lines '#4\b')
if ! printf '%s' "$p5" | grep -Eqi 'fail|red|broken|✗|❌'; then fail checks_reported "#5 not shown failing: $(printf '%s' "$p5" | head -1 | cut -c1-120)"
elif ! printf '%s' "$p4" | grep -Eqi 'pass|green|success|✓|✅'; then fail checks_reported "#4 not shown passing: $(printf '%s' "$p4" | head -1 | cut -c1-120)"
else pass checks_reported; fi
check_next_move
